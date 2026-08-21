import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// INSTA WALK SEARCH SERVICE
/// ============================================================
///
/// OWNER FLOW
/// ------------------------------------------------------------
/// Owner starts Insta Walk
/// -> owner location snapshot saved
/// -> request created in walk_requests
/// -> status = searching
/// -> nearby eligible Walker can accept
/// -> status = accepted
/// -> Owner receives accepted Walker information
///
/// SEARCH LIMIT
/// ------------------------------------------------------------
/// Maximum radius: 3 KM
/// Maximum duration: 2 minutes
///
/// LOCATION PRIVACY
/// ------------------------------------------------------------
/// ownerLocation is only a location snapshot used for matching.
///
/// This service does NOT:
/// - stream Owner location
/// - send live Owner location
/// - provide Walker list/count to Owner
/// - provide Walker location during searching
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

  static const double searchRadiusKm = 3.0;

  static const Duration requestDuration =
      Duration(minutes: 2);

  /// Used by the UI countdown.
  static const int requestDurationSeconds =
      120;

  // ============================================================
  // ACTIVE LISTENER
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
    GeoPoint? ownerLocation,
  }) async {
    final User? user =
        _auth.currentUser;

    // ==========================================================
    // LOGIN
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
    // OWNER ID
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
    // ADDRESS
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
      final InstaWalkRequestState state =
          await getRequestState(
        _activeRequestId!,
      );

      if (state.isSearching) {
        return InstaWalkSearchResult.success(
          requestId:
              _activeRequestId!,
          expiresAt:
              state.expiresAt ??
                  DateTime.now().add(
                    requestDuration,
                  ),
        );
      }

      if (state.isAccepted) {
        return InstaWalkSearchResult.success(
          requestId:
              _activeRequestId!,
          expiresAt:
              state.expiresAt ??
                  DateTime.now(),
        );
      }

      _activeRequestId = null;
    }

    try {
      await _requestSubscription?.cancel();

      _requestSubscription = null;

      // ========================================================
      // REQUEST DOCUMENT
      // ========================================================

      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc();

      // ========================================================
      // TIME
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
        'requestId':
            requestRef.id,

        'status':
            'searching',

        'searchType':
            'insta_walk',

        'senderRole':
            'owner',

        'senderUid':
            ownerAuthUid,

        'ownerId':
            cleanOwnerId,

        'ownerAuthUid':
            ownerAuthUid,

        'ownerName':
            ownerName.trim().isEmpty
                ? 'Dog Owner'
                : ownerName.trim(),

        'address':
            cleanAddress,

        'searchRadiusKm':
            searchRadiusKm,

        // ======================================================
        // LOCATION SNAPSHOT ONLY
        // ======================================================

        if (ownerLocation != null)
          'ownerLocation':
              ownerLocation,

        'ownerLocationType':
            'search_snapshot',

        // ======================================================
        // WALKER
        // ======================================================

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

        // ======================================================
        // TIMESTAMPS
        // ======================================================

        'createdAt':
            FieldValue.serverTimestamp(),

        'expiresAt':
            Timestamp.fromDate(
          expiresAt,
        ),
      };

      await requestRef.set(
        requestData,
      );

      _activeRequestId =
          requestRef.id;

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

    await _requestSubscription?.cancel();

    _requestSubscription = null;

    _activeRequestId =
        cleanRequestId;

    bool acceptedCallbackSent =
        false;

    bool expiredCallbackSent =
        false;

    bool cancelledCallbackSent =
        false;

    final DocumentReference<
        Map<String, dynamic>> requestRef =
        _firestore
            .collection(
              walkRequestsCollection,
            )
            .doc(
              cleanRequestId,
            );

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

          onAccepted(
            InstaWalkAcceptedData.fromMap(
              data,
            ),
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
        final DateTime? expiresAt =
            _readExpiresAt(
          data,
        );

        if (expiresAt != null &&
            !DateTime.now()
                .isBefore(expiresAt)) {
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

        // ======================================================
        // ACCEPTED
        // ======================================================

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

        // ======================================================
        // SEARCHING
        // ======================================================

        if (status == 'searching') {
          final DateTime? expiresAt =
              _readExpiresAt(
            data,
          );

          if (expiresAt != null &&
              !DateTime.now()
                  .isBefore(expiresAt)) {
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

      if (status == 'accepted') {
        return false;
      }

      if (status != 'searching') {
        await _clearActiveRequest();
        return false;
      }

      await requestRef.update({
        'status':
            'owner_cancelled',
        'cancelledAt':
            FieldValue.serverTimestamp(),
        'cancelledBy':
            'owner',
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

      if (status == 'accepted') {
        return false;
      }

      if (status != 'searching') {
        await _clearActiveRequest();
        return false;
      }

      final DateTime? expiresAt =
          _readExpiresAt(
        data,
      );

      // ========================================================
      // DON'T EXPIRE EARLY
      // ========================================================

      if (expiresAt != null &&
          DateTime.now()
              .isBefore(expiresAt)) {
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
  // CHECK EXPIRY
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

      if (status == 'accepted') {
        return false;
      }

      if (status == 'expired' ||
          status == 'cancelled' ||
          status == 'owner_cancelled' ||
          status == 'walker_cancelled') {
        return true;
      }

      final DateTime? expiresAt =
          _readExpiresAt(
        data,
      );

      if (expiresAt == null) {
        return false;
      }

      return !DateTime.now()
          .isBefore(expiresAt);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // REMAINING TIME
  // ============================================================

  Future<Duration?> getRemainingTime(
    String requestId,
  ) async {
    final String cleanId =
        requestId.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection(
                walkRequestsCollection,
              )
              .doc(
                cleanId,
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
  // FIREBASE ERROR
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

    String walkerUid =
        data['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (walkerUid.isEmpty) {
      walkerUid =
          data['acceptedBy']
                  ?.toString()
                  .trim() ??
              '';
    }

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

  String get searchType =>
      data?['searchType']
              ?.toString()
              .trim() ??
          '';

  String get ownerId =>
      data?['ownerId']
              ?.toString()
              .trim() ??
          '';

  String get walkerUid {
    final String uid =
        data?['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (uid.isNotEmpty) {
      return uid;
    }

    return data?['acceptedBy']
            ?.toString()
            .trim() ??
        '';
  }
}
