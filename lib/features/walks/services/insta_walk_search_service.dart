import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// INSTA WALK SEARCH SERVICE
/// ============================================================
///
/// Owner side Insta Walk flow:
///
/// 1. Owner "Find a Walker" दबाता है
/// 2. Owner की current/search location के आधार पर request बनती है
/// 3. Request maximum 3 KM radius के walkers के लिए होती है
/// 4. Walker request accept करता है
/// 5. Owner को तभी पता चलता है कि Walker ने accept किया
/// 6. Accept होने पर searching बंद
/// 7. Radar/UI बंद करने का signal मिलता है
/// 8. Request 2 minutes बाद automatically expire हो जाती है
///
/// IMPORTANT:
/// ------------------------------------------------------------
/// App background / screen change:
/// Firestore में expiresAt save होता है, इसलिए request की
/// वास्तविक validity local Timer पर depend नहीं करती।
///
/// अगर Owner Home -> Walks -> Home जाता है तो Firestore request
/// बनी रहती है।
///
/// अगर app पूरी तरह बंद हो जाए तो local Dart Timer रुक सकता है,
/// लेकिन Firestore में expiresAt मौजूद रहेगा। अगली बार app खुलने
/// पर service request की वास्तविक स्थिति check कर सकती है।
///
/// Owner को Walker की availability/list नहीं दिखाई जाती।
/// Owner को सिर्फ "accepted" होने पर Walker की जानकारी मिलेगी।
/// ============================================================

class InstaWalkSearchService {
  InstaWalkSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // COLLECTION
  // ============================================================

  static const String walkRequestsCollection =
      'walk_requests';

  static const String ownerProfilesCollection =
      'ownerProfiles';

  // ============================================================
  // SEARCH SETTINGS
  // ============================================================

  static const double searchRadiusKm = 3.0;

  static const Duration requestDuration =
      Duration(minutes: 2);

  // ============================================================
  // ACTIVE REQUEST LISTENER
  // ============================================================

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  // ============================================================
  // ACTIVE REQUEST ID
  // ============================================================

  String? _activeRequestId;

  String? get activeRequestId =>
      _activeRequestId;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await _requestSubscription?.cancel();
    _requestSubscription = null;
  }

  // ============================================================
  // FIND OWNER PROFILE
  // ============================================================

  Future<QueryDocumentSnapshot<
      Map<String, dynamic>>?> findOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final QuerySnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection(ownerProfilesCollection)
            .where(
              'authUid',
              isEqualTo: user.uid,
            )
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first;
  }

  // ============================================================
  // CREATE SEARCH REQUEST
  // ============================================================

  Future<InstaWalkSearchResult> startSearch({
    required String ownerId,
    required String ownerName,
    required String address,

    /// Owner की search/current location.
    ///
    /// यह location Walker को expose करने के लिए नहीं है।
    /// यह केवल nearby Walker matching के लिए है।
    GeoPoint? ownerLocation,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const InstaWalkSearchResult.failure(
        message: 'Please login first.',
      );
    }

    final String ownerAuthUid =
        user.uid.trim();

    if (ownerAuthUid.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner UID is missing.',
      );
    }

    if (ownerId.trim().isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner ID is missing.',
      );
    }

    if (address.trim().isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner address is missing.',
      );
    }

    try {
      // ========================================================
      // STOP PREVIOUS LISTENER
      // ========================================================

      await _requestSubscription?.cancel();
      _requestSubscription = null;

      // ========================================================
      // REQUEST REFERENCE
      // ========================================================

      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(walkRequestsCollection)
              .doc();

      // ========================================================
      // TIME
      // ========================================================

      final DateTime now =
          DateTime.now();

      final DateTime expiresAt =
          now.add(requestDuration);

      // ========================================================
      // REQUEST DATA
      // ========================================================

      final Map<String, dynamic> requestData =
          <String, dynamic>{
        // ------------------------------------------------------
        // REQUEST
        // ------------------------------------------------------

        'requestId': requestRef.id,

        'status': 'searching',

        'senderRole': 'owner',

        'senderUid': ownerAuthUid,

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId':
            ownerId.trim(),

        'ownerAuthUid':
            ownerAuthUid,

        'ownerName':
            ownerName.trim().isEmpty
                ? 'Dog Owner'
                : ownerName.trim(),

        // ------------------------------------------------------
        // DESTINATION / ADDRESS
        // ------------------------------------------------------

        'address':
            address.trim(),

        // ------------------------------------------------------
        // SEARCH
        // ------------------------------------------------------

        'searchType':
            'insta_walk',

        'searchRadiusKm':
            searchRadiusKm,

        // ------------------------------------------------------
        // LOCATION
        // ------------------------------------------------------
        //
        // Only used for matching nearby walkers.
        //
        // IMPORTANT:
        // Walker app should NOT expose owner's live location.
        // This is the owner's selected/current request location.
        // ------------------------------------------------------

        if (ownerLocation != null)
          'ownerLocation':
              ownerLocation,

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerUid': null,

        'walkerId': null,

        'acceptedBy': null,

        'acceptedAt': null,

        // ------------------------------------------------------
        // TIMESTAMP
        // ------------------------------------------------------

        'createdAt':
            FieldValue.serverTimestamp(),

        'expiresAt':
            Timestamp.fromDate(
          expiresAt,
        ),
      };

      // ========================================================
      // CREATE REQUEST
      // ========================================================

      await requestRef.set(
        requestData,
      );

      _activeRequestId =
          requestRef.id;

      return InstaWalkSearchResult.success(
        requestId: requestRef.id,
        expiresAt: expiresAt,
      );
    } on FirebaseException catch (e) {
      return InstaWalkSearchResult.failure(
        message:
            _firebaseErrorMessage(e),
        errorCode:
            e.code,
      );
    } catch (e) {
      return InstaWalkSearchResult.failure(
        message:
            'Unable to start Insta Walk search.',
        errorCode:
            'unknown',
      );
    }
  }

  // ============================================================
  // LISTEN FOR WALKER ACCEPT
  // ============================================================
  ///
  /// Owner को Walker की list नहीं मिलेगी।
  ///
  /// सिर्फ request document का status observe होगा:
  ///
  /// searching
  /// accepted
  /// expired
  /// cancelled
  ///
  /// Accepted होने पर callback चलेगा।
  // ============================================================

  Future<void> listenForRequest({
    required String requestId,

    required void Function(
      InstaWalkAcceptedData data,
    ) onAccepted,

    void Function()? onExpired,

    void Function()? onCancelled,

    void Function(
      Object error,
    )? onError,
  }) async {
    await _requestSubscription?.cancel();

    final DocumentReference<
        Map<String, dynamic>> requestRef =
        _firestore
            .collection(
              walkRequestsCollection,
            )
            .doc(requestId);

    _activeRequestId =
        requestId;

    _requestSubscription =
        requestRef.snapshots().listen(
      (
        DocumentSnapshot<
            Map<String, dynamic>> snapshot,
      ) {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        // ======================================================
        // ACCEPTED
        // ======================================================

        if (status == 'accepted') {
          final InstaWalkAcceptedData accepted =
              InstaWalkAcceptedData.fromMap(
            data,
          );

          onAccepted(accepted);
          return;
        }

        // ======================================================
        // EXPIRED
        // ======================================================

        if (status == 'expired') {
          onExpired?.call();
          return;
        }

        // ======================================================
        // CANCELLED
        // ======================================================

        if (status == 'cancelled' ||
            status == 'owner_cancelled' ||
            status == 'walker_cancelled') {
          onCancelled?.call();
          return;
        }
      },
      onError: (Object error) {
        onError?.call(error);
      },
    );
  }

  // ============================================================
  // GET REQUEST STATUS
  // ============================================================

  Future<InstaWalkRequestState>
      getRequestState(
    String requestId,
  ) async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(requestId)
              .get();

      if (!snapshot.exists) {
        return const InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.notFound,
        );
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return const InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.notFound,
        );
      }

      final String status =
          data['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      switch (status) {
        case 'searching':
          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.searching,
            data: data,
          );

        case 'accepted':
          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.accepted,
            data: data,
          );

        case 'expired':
          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.expired,
            data: data,
          );

        case 'cancelled':
        case 'owner_cancelled':
        case 'walker_cancelled':
          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.cancelled,
            data: data,
          );

        default:
          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.unknown,
            data: data,
          );
      }
    } on FirebaseException catch (e) {
      return InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            _firebaseErrorMessage(e),
      );
    } catch (e) {
      return const InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            'Unable to check walk request.',
      );
    }
  }

  // ============================================================
  // CANCEL SEARCH
  // ============================================================

  Future<bool> cancelSearch({
    String? requestId,
  }) async {
    final String? id =
        requestId ?? _activeRequestId;

    if (id == null ||
        id.trim().isEmpty) {
      return false;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(id);

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await requestRef.get();

      if (!snapshot.exists) {
        await _clearActiveRequest();
        return false;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      final String status =
          data?['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      // ========================================================
      // ACCEPTED REQUEST CANCEL नहीं होगी यहाँ से
      // ========================================================

      if (status == 'accepted') {
        return false;
      }

      if (status == 'searching') {
        await requestRef.update({
          'status':
              'owner_cancelled',
          'cancelledAt':
              FieldValue.serverTimestamp(),
          'cancelledBy':
              'owner',
        });
      }

      await _clearActiveRequest();

      return true;
    } on FirebaseException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // EXPIRE REQUEST
  // ============================================================

  Future<bool> expireRequest({
    String? requestId,
  }) async {
    final String? id =
        requestId ?? _activeRequestId;

    if (id == null ||
        id.trim().isEmpty) {
      return false;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(id);

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await requestRef.get();

      if (!snapshot.exists) {
        await _clearActiveRequest();
        return false;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      final String status =
          data?['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      // ========================================================
      // केवल SEARCHING request expire होगी
      // ========================================================

      if (status != 'searching') {
        return false;
      }

      await requestRef.update({
        'status':
            'expired',
        'expiredAt':
            FieldValue.serverTimestamp(),
      });

      await _clearActiveRequest();

      return true;
    } on FirebaseException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CHECK LOCAL EXPIRY
  // ============================================================
  ///
  /// यह method app दोबारा open होने पर useful है।
  ///
  /// Firestore का expiresAt देखकर पता चलता है कि request अभी
  /// valid है या नहीं।
  // ============================================================

  Future<bool> isRequestExpired(
    String requestId,
  ) async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(requestId)
              .get();

      if (!snapshot.exists) {
        return true;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return true;
      }

      final String status =
          data['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (status == 'accepted') {
        return false;
      }

      if (status == 'expired') {
        return true;
      }

      final dynamic expiresAt =
          data['expiresAt'];

      if (expiresAt is Timestamp) {
        return DateTime.now()
            .isAfter(
          expiresAt.toDate(),
        );
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CLEAR ACTIVE REQUEST
  // ============================================================

  Future<void> _clearActiveRequest() async {
    await _requestSubscription?.cancel();

    _requestSubscription = null;
    _activeRequestId = null;
  }

  // ============================================================
  // FIREBASE ERROR MESSAGE
  // ============================================================

  String _firebaseErrorMessage(
    FirebaseException e,
  ) {
    switch (e.code) {
      case 'permission-denied':
        return 'Walk request was blocked by Firestore rules.';

      case 'unavailable':
        return 'Network is unavailable. Please try again.';

      case 'failed-precondition':
        return 'Firestore is not ready for this request.';

      case 'not-found':
        return 'Walk request was not found.';

      default:
        return 'Unable to process Insta Walk request.';
    }
  }
}

// =================================================================
// SEARCH RESULT
// =================================================================

class InstaWalkSearchResult {
  final bool success;
  final String? requestId;
  final DateTime? expiresAt;
  final String? message;
  final String? errorCode;

  const InstaWalkSearchResult({
    required this.success,
    this.requestId,
    this.expiresAt,
    this.message,
    this.errorCode,
  });

  const InstaWalkSearchResult.success({
    required String requestId,
    required DateTime expiresAt,
  }) : this(
          success: true,
          requestId: requestId,
          expiresAt: expiresAt,
        );

  const InstaWalkSearchResult.failure({
    required String message,
    String? errorCode,
  }) : this(
          success: false,
          message: message,
          errorCode: errorCode,
        );
}

// =================================================================
// ACCEPTED DATA
// =================================================================

class InstaWalkAcceptedData {
  final String requestId;
  final String ownerId;
  final String ownerAuthUid;
  final String ownerName;

  final String walkerUid;
  final String walkerId;
  final String walkerName;

  final DateTime? acceptedAt;

  final Map<String, dynamic> rawData;

  const InstaWalkAcceptedData({
    required this.requestId,
    required this.ownerId,
    required this.ownerAuthUid,
    required this.ownerName,
    required this.walkerUid,
    required this.walkerId,
    required this.walkerName,
    required this.acceptedAt,
    required this.rawData,
  });

  factory InstaWalkAcceptedData.fromMap(
    Map<String, dynamic> data,
  ) {
    final dynamic acceptedAtValue =
        data['acceptedAt'];

    DateTime? acceptedAt;

    if (acceptedAtValue is Timestamp) {
      acceptedAt =
          acceptedAtValue.toDate();
    }

    return InstaWalkAcceptedData(
      requestId:
          data['requestId']
                  ?.toString() ??
              '',

      ownerId:
          data['ownerId']
                  ?.toString() ??
              '',

      ownerAuthUid:
          data['ownerAuthUid']
                  ?.toString() ??
              '',

      ownerName:
          data['ownerName']
                  ?.toString() ??
              'Dog Owner',

      walkerUid:
          data['walkerUid']
                  ?.toString() ??
              data['acceptedBy']
                  ?.toString() ??
              '',

      walkerId:
          data['walkerId']
                  ?.toString() ??
              '',

      walkerName:
          data['walkerName']
                  ?.toString() ??
              'Walker',

      acceptedAt:
          acceptedAt,

      rawData:
          Map<String, dynamic>.from(
        data,
      ),
    );
  }
}

// =================================================================
// REQUEST STATUS
// =================================================================

enum InstaWalkRequestStatus {
  searching,
  accepted,
  expired,
  cancelled,
  notFound,
  unknown,
  error,
}

// =================================================================
// REQUEST STATE
// =================================================================

class InstaWalkRequestState {
  final InstaWalkRequestStatus status;

  final Map<String, dynamic>? data;

  final String? errorMessage;

  const InstaWalkRequestState({
    required this.status,
    this.data,
    this.errorMessage,
  });

  bool get isSearching =>
      status ==
      InstaWalkRequestStatus.searching;

  bool get isAccepted =>
      status ==
      InstaWalkRequestStatus.accepted;

  bool get isExpired =>
      status ==
      InstaWalkRequestStatus.expired;

  bool get isCancelled =>
      status ==
      InstaWalkRequestStatus.cancelled;

  bool get hasError =>
      status ==
      InstaWalkRequestStatus.error;
}
