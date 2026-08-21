import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// INSTA WALK SEARCH SERVICE
/// ============================================================
///
/// OWNER SIDE FLOW
/// ------------------------------------------------------------
///
/// 1. Owner "Find a Walker" दबाता है
/// 2. Owner की selected/current location request में save होती है
/// 3. Walker matching maximum 3 KM radius में होगी
/// 4. Owner को searching के दौरान कोई Walker list नहीं मिलेगी
/// 5. Owner को यह भी नहीं पता चलेगा कि कितने Walker available हैं
/// 6. Nearby eligible Walker request accept करेगा
/// 7. तभी request status = accepted होगा
/// 8. Owner को accepted Walker की जानकारी मिलेगी
/// 9. Accept होते ही Radar/Search बंद किया जा सकता है
/// 10. Searching request maximum 2 minutes valid है
///
/// IMPORTANT LOCATION PRIVACY
/// ------------------------------------------------------------
///
/// ownerLocation केवल nearby Walker matching के लिए है।
///
/// इस service में:
///
/// ❌ Owner की live location Walker को नहीं भेजी जाती
/// ❌ Walker को Owner की live tracking नहीं दी जाती
/// ❌ Searching में Owner को Walker की location नहीं मिलती
/// ❌ Searching में Owner को Walker count/list नहीं मिलता
///
/// ACCEPT होने के बाद:
///
/// ✅ Owner को accepted Walker की information मिल सकती है
/// ✅ अलग Live Walk system से Walker location दिखाई जा सकती है
///
/// IMPORTANT BACKGROUND BEHAVIOUR
/// ------------------------------------------------------------
///
/// Firestore में expiresAt save होता है। इसलिए UI का local Timer
/// request की वास्तविक validity का source नहीं है.
///
/// Home -> Walks -> Home:
/// request Firestore में बनी रहती है.
///
/// App पूरी तरह बंद:
/// local Timer रुक सकता है, लेकिन expiresAt Firestore में रहता है.
///
/// App दोबारा खुलने पर recoverActiveRequest() से existing request
/// check की जा सकती है.
///
/// ============================================================

class InstaWalkSearchService {
  InstaWalkSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth =
            auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String walkRequestsCollection =
      'walk_requests';

  static const String ownerProfilesCollection =
      'ownerProfiles';

  // ============================================================
  // SEARCH SETTINGS
  // ============================================================

  /// Maximum search radius.
  static const double searchRadiusKm = 3.0;

  /// Maximum time for a searching request.
  static const Duration requestDuration =
      Duration(minutes: 2);

  // ============================================================
  // ACTIVE REQUEST LISTENER
  // ============================================================

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  // ============================================================
  // ACTIVE REQUEST
  // ============================================================

  String? _activeRequestId;

  String? get activeRequestId =>
      _activeRequestId;

  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  String? get currentAuthUid =>
      _auth.currentUser?.uid;

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
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                ownerProfilesCollection,
              )
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
    } on FirebaseException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // START SEARCH
  // ============================================================

  Future<InstaWalkSearchResult> startSearch({
    required String ownerId,
    required String ownerName,
    required String address,

    /// Owner की search/current location.
    ///
    /// यह Walker को live location के रूप में expose नहीं होगी।
    ///
    /// इसका उपयोग nearby Walker matching के लिए होगा।
    GeoPoint? ownerLocation,
  }) async {
    final User? user =
        _auth.currentUser;

    // ==========================================================
    // LOGIN CHECK
    // ==========================================================

    if (user == null) {
      return const InstaWalkSearchResult.failure(
        message:
            'Please login first.',
      );
    }

    final String ownerAuthUid =
        user.uid.trim();

    if (ownerAuthUid.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message:
            'Owner UID is missing.',
      );
    }

    // ==========================================================
    // OWNER ID CHECK
    // ==========================================================

    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message:
            'Owner ID is missing.',
      );
    }

    // ==========================================================
    // ADDRESS CHECK
    // ==========================================================

    final String cleanAddress =
        address.trim();

    if (cleanAddress.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message:
            'Owner address is missing.',
      );
    }

    // ==========================================================
    // PREVENT DUPLICATE SEARCH
    // ==========================================================

    if (hasActiveRequest) {
      final InstaWalkRequestState currentState =
          await getRequestState(
        _activeRequestId!,
      );

      if (currentState.isSearching) {
        return InstaWalkSearchResult.success(
          requestId:
              _activeRequestId!,
          expiresAt:
              _readExpiresAt(
            currentState.data,
          ),
        );
      }

      _activeRequestId = null;
    }

    try {
      // ========================================================
      // STOP OLD LISTENER
      // ========================================================

      await _requestSubscription?.cancel();

      _requestSubscription = null;

      // ========================================================
      // CREATE REQUEST DOCUMENT
      // ========================================================

      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc();

      // ========================================================
      // REQUEST TIME
      // ========================================================

      final DateTime now =
          DateTime.now();

      final DateTime expiresAt =
          now.add(
        requestDuration,
      );

      // ========================================================
      // REQUEST DATA
      // ========================================================

      final Map<String, dynamic> requestData =
          <String, dynamic>{
        // ------------------------------------------------------
        // REQUEST ID
        // ------------------------------------------------------

        'requestId':
            requestRef.id,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status':
            'searching',

        // ------------------------------------------------------
        // REQUEST TYPE
        // ------------------------------------------------------

        'searchType':
            'insta_walk',

        'senderRole':
            'owner',

        'senderUid':
            ownerAuthUid,

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId':
            cleanOwnerId,

        'ownerAuthUid':
            ownerAuthUid,

        'ownerName':
            ownerName.trim().isEmpty
                ? 'Dog Owner'
                : ownerName.trim(),

        // ------------------------------------------------------
        // DESTINATION
        // ------------------------------------------------------

        'address':
            cleanAddress,

        // ------------------------------------------------------
        // SEARCH RADIUS
        // ------------------------------------------------------

        'searchRadiusKm':
            searchRadiusKm,

        // ------------------------------------------------------
        // OWNER LOCATION
        // ------------------------------------------------------
        //
        // केवल nearby matching के लिए।
        //
        // यह Owner की live location sharing नहीं है।
        //
        // Walker side को इसे read करके Owner की live tracking
        // नहीं करनी चाहिए।
        // ------------------------------------------------------

        if (ownerLocation != null)
          'ownerLocation':
              ownerLocation,

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerUid':
            null,

        'walkerId':
            null,

        'walkerName':
            null,

        'acceptedBy':
            null,

        'acceptedAt':
            null,

        // ------------------------------------------------------
        // TIMESTAMPS
        // ------------------------------------------------------

        'createdAt':
            FieldValue.serverTimestamp(),

        'expiresAt':
            Timestamp.fromDate(
          expiresAt,
        ),
      };

      // ========================================================
      // SAVE REQUEST
      // ========================================================

      await requestRef.set(
        requestData,
      );

      // ========================================================
      // SAVE ACTIVE REQUEST
      // ========================================================

      _activeRequestId =
          requestRef.id;

      // ========================================================
      // SUCCESS
      // ========================================================

      return InstaWalkSearchResult.success(
        requestId:
            requestRef.id,
        expiresAt:
            expiresAt,
      );
    } on FirebaseException catch (e) {
      return InstaWalkSearchResult.failure(
        message:
            _firebaseErrorMessage(e),
        errorCode:
            e.code,
      );
    } catch (_) {
      return const InstaWalkSearchResult.failure(
        message:
            'Unable to start Insta Walk search.',
        errorCode:
            'unknown',
      );
    }
  }

  // ============================================================
  // LISTEN FOR REQUEST
  // ============================================================
  ///
  /// Owner को केवल request status changes मिलेंगे।
  ///
  /// searching
  /// accepted
  /// expired
  /// cancelled
  ///
  /// Searching में Walker list नहीं भेजी जाती।
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
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      return;
    }

    // ==========================================================
    // STOP PREVIOUS LISTENER
    // ==========================================================

    await _requestSubscription?.cancel();

    _requestSubscription = null;

    // ==========================================================
    // ACTIVE REQUEST
    // ==========================================================

    _activeRequestId =
        cleanRequestId;

    // ==========================================================
    // CALLBACK PROTECTION
    // ==========================================================
    //
    // Firestore listener multiple times trigger हो सकता है।
    // Accepted callback एक ही बार देना है।
    // ==========================================================

    bool acceptedCallbackSent =
        false;

    bool expiredCallbackSent =
        false;

    bool cancelledCallbackSent =
        false;

    // ==========================================================
    // REQUEST REF
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> requestRef =
        _firestore
            .collection(
              walkRequestsCollection,
            )
            .doc(
              cleanRequestId,
            );

    // ==========================================================
    // LISTEN
    // ==========================================================

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
          if (acceptedCallbackSent) {
            return;
          }

          acceptedCallbackSent = true;

          final InstaWalkAcceptedData accepted =
              InstaWalkAcceptedData.fromMap(
            data,
          );

          onAccepted(
            accepted,
          );

          return;
        }

        // ======================================================
        // EXPIRED
        // ======================================================

        if (status == 'expired') {
          if (expiredCallbackSent) {
            return;
          }

          expiredCallbackSent = true;

          onExpired?.call();

          return;
        }

        // ======================================================
        // CANCELLED
        // ======================================================

        if (status == 'cancelled' ||
            status == 'owner_cancelled' ||
            status == 'walker_cancelled') {
          if (cancelledCallbackSent) {
            return;
          }

          cancelledCallbackSent = true;

          onCancelled?.call();

          return;
        }
      },
      onError: (
        Object error,
      ) {
        onError?.call(
          error,
        );
      },
    );
  }

  // ============================================================
  // GET REQUEST STATE
  // ============================================================

  Future<InstaWalkRequestState>
      getRequestState(
    String requestId,
  ) async {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      return const InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.notFound,
      );
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(
                cleanRequestId,
              )
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

      // ========================================================
      // SEARCHING
      // ========================================================

      if (status == 'searching') {
        // ------------------------------------------------------
        // LOCAL EXPIRY SAFETY
        // ------------------------------------------------------

        final DateTime? expiresAt =
            _readExpiresAt(
          data,
        );

        if (expiresAt != null &&
            DateTime.now()
                .isAfter(
              expiresAt,
            )) {
          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.expired,
            data:
                data,
          );
        }

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.searching,
          data:
              data,
        );
      }

      // ========================================================
      // ACCEPTED
      // ========================================================

      if (status == 'accepted') {
        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.accepted,
          data:
              data,
        );
      }

      // ========================================================
      // EXPIRED
      // ========================================================

      if (status == 'expired') {
        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.expired,
          data:
              data,
        );
      }

      // ========================================================
      // CANCELLED
      // ========================================================

      if (status == 'cancelled' ||
          status == 'owner_cancelled' ||
          status == 'walker_cancelled') {
        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.cancelled,
          data:
              data,
        );
      }

      // ========================================================
      // UNKNOWN
      // ========================================================

      return InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.unknown,
        data:
            data,
      );
    } on FirebaseException catch (e) {
      return InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            _firebaseErrorMessage(e),
      );
    } catch (_) {
      return const InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            'Unable to check walk request.',
      );
    }
  }

  // ============================================================
  // RECOVER ACTIVE REQUEST
  // ============================================================
  ///
  /// Home -> Walks -> Home या app restart के बाद Owner का
  /// active Insta Walk request ढूंढने के लिए।
  ///
  /// यह Owner की अपनी request ही खोजता है।
  ///
  /// Priority:
  ///
  /// searching
  /// फिर accepted
  ///
  /// Expired/cancelled request वापस active नहीं होगी।
  // ============================================================

  Future<InstaWalkRequestState>
      recoverActiveRequest() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return const InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.notFound,
      );
    }

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .where(
                'ownerAuthUid',
                isEqualTo: user.uid,
              )
              .where(
                'searchType',
                isEqualTo: 'insta_walk',
              )
              .orderBy(
                'createdAt',
                descending: true,
              )
              .limit(10)
              .get();

      if (snapshot.docs.isEmpty) {
        _activeRequestId = null;

        return const InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.notFound,
        );
      }

      // ========================================================
      // SEARCH ACTIVE REQUEST
      // ========================================================

      for (final QueryDocumentSnapshot<
          Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        // ------------------------------------------------------
        // ACCEPTED
        // ------------------------------------------------------

        if (status == 'accepted') {
          _activeRequestId =
              doc.id;

          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.accepted,
            data:
                data,
          );
        }

        // ------------------------------------------------------
        // SEARCHING
        // ------------------------------------------------------

        if (status == 'searching') {
          final DateTime? expiresAt =
              _readExpiresAt(
            data,
          );

          // ----------------------------------------------------
          // EXPIRED LOCALLY
          // ----------------------------------------------------

          if (expiresAt != null &&
              DateTime.now()
                  .isAfter(
                expiresAt,
              )) {
            continue;
          }

          _activeRequestId =
              doc.id;

          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.searching,
            data:
                data,
          );
        }
      }

      _activeRequestId = null;

      return const InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.notFound,
      );
    } on FirebaseException catch (e) {
      return InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            _firebaseErrorMessage(e),
      );
    } catch (_) {
      return const InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.error,
        errorMessage:
            'Unable to recover Insta Walk request.',
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

    final String cleanId =
        id.trim();

    try {
      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(
                cleanId,
              );

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
      // ACCEPTED CANNOT BE CANCELLED BY SEARCH CANCEL
      // ========================================================

      if (status == 'accepted') {
        return false;
      }

      // ========================================================
      // ONLY SEARCHING CAN BE CANCELLED
      // ========================================================

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

    final String cleanId =
        id.trim();

    try {
      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(
                cleanId,
              );

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
      // ACCEPTED NEVER EXPIRES FROM THIS SEARCH METHOD
      // ========================================================

      if (status == 'accepted') {
        return false;
      }

      // ========================================================
      // ONLY SEARCHING REQUEST EXPIRES
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
  // CHECK REQUEST EXPIRY
  // ============================================================

  Future<bool> isRequestExpired(
    String requestId,
  ) async {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      return true;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(
                cleanRequestId,
              )
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

      // ========================================================
      // ACCEPTED
      // ========================================================

      if (status == 'accepted') {
        return false;
      }

      // ========================================================
      // ALREADY EXPIRED
      // ========================================================

      if (status == 'expired') {
        return true;
      }

      // ========================================================
      // CANCELLED
      // ========================================================

      if (status == 'cancelled' ||
          status == 'owner_cancelled' ||
          status == 'walker_cancelled') {
        return true;
      }

      // ========================================================
      // CHECK expiresAt
      // ========================================================

      final DateTime? expiresAt =
          _readExpiresAt(
        data,
      );

      if (expiresAt == null) {
        return false;
      }

      return DateTime.now()
          .isAfter(
        expiresAt,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // GET REMAINING TIME
  // ============================================================

  Future<Duration?> getRemainingTime(
    String requestId,
  ) async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(
                requestId.trim(),
              )
              .get();

      if (!snapshot.exists) {
        return null;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return null;
      }

      final String status =
          data['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (status != 'searching') {
        return null;
      }

      final DateTime? expiresAt =
          _readExpiresAt(
        data,
      );

      if (expiresAt == null) {
        return null;
      }

      final Duration remaining =
          expiresAt.difference(
        DateTime.now(),
      );

      if (remaining.isNegative) {
        return Duration.zero;
      }

      return remaining;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CLEAR ACTIVE REQUEST
  // ============================================================

  Future<void> clearActiveRequest() async {
    await _clearActiveRequest();
  }

  Future<void> _clearActiveRequest() async {
    await _requestSubscription?.cancel();

    _requestSubscription = null;

    _activeRequestId = null;
  }

  // ============================================================
  // READ EXPIRES AT
  // ============================================================

  DateTime? _readExpiresAt(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }

    final dynamic value =
        data['expiresAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
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

      case 'unauthenticated':
        return 'Please login again.';

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

  bool get hasError =>
      !success;

  bool get hasRequestId =>
      requestId != null &&
      requestId!.trim().isNotEmpty;
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
    } else if (acceptedAtValue is DateTime) {
      acceptedAt =
          acceptedAtValue;
    }

    final String walkerUid =
        data['walkerUid']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
            ? data['walkerUid']
                  .toString()
                  .trim()
            : data['acceptedBy']
                    ?.toString()
                    .trim() ??
                '';

    return InstaWalkAcceptedData(
      requestId:
          data['requestId']
                  ?.toString()
                  .trim() ??
              '',

      ownerId:
          data['ownerId']
                  ?.toString()
                  .trim() ??
              '',

      ownerAuthUid:
          data['ownerAuthUid']
                  ?.toString()
                  .trim() ??
              '',

      ownerName:
          data['ownerName']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? data['ownerName']
                .toString()
                .trim()
          : 'Dog Owner',

      walkerUid:
          walkerUid,

      walkerId:
          data['walkerId']
                  ?.toString()
                  .trim() ??
              '',

      walkerName:
          data['walkerName']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
          ? data['walkerName']
                .toString()
                .trim()
          : 'Walker',

      acceptedAt:
          acceptedAt,

      rawData:
          Map<String, dynamic>.from(
        data,
      ),
    );
  }

  bool get hasWalker =>
      walkerUid.isNotEmpty;
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

  // ==============================================================
  // STATUS HELPERS
  // ==============================================================

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

  bool get isNotFound =>
      status ==
      InstaWalkRequestStatus.notFound;

  bool get isUnknown =>
      status ==
      InstaWalkRequestStatus.unknown;

  bool get hasError =>
      status ==
      InstaWalkRequestStatus.error;

  // ==============================================================
  // REQUEST ID
  // ==============================================================

  String? get requestId {
    final String value =
        data?['requestId']
                ?.toString()
                .trim() ??
            '';

    return value.isEmpty
        ? null
        : value;
  }

  // ==============================================================
  // EXPIRY
  // ==============================================================

  DateTime? get expiresAt {
    final dynamic value =
        data?['expiresAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ==============================================================
  // SEARCH TYPE
  // ==============================================================

  String get searchType =>
      data?['searchType']
              ?.toString()
              .trim() ??
          '';

  // ==============================================================
  // OWNER ID
  // ==============================================================

  String get ownerId =>
      data?['ownerId']
              ?.toString()
              .trim() ??
          '';

  // ==============================================================
  // WALKER UID
  // ==============================================================

  String get walkerUid =>
      data?['walkerUid']
              ?.toString()
              .trim() ??
          data?['acceptedBy']
                  ?.toString()
                  .trim() ??
              '';
}
