import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InstaWalkSearchService {
  InstaWalkSearchService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String walkRequestsCollection = 'walk_requests';
  static const String ownerProfilesCollection = 'ownerProfiles';

  // ============================================================
  // SEARCH CONFIGURATION
  // ============================================================

  static const double searchRadiusKm = 3.0;

  static const Duration firstSearchDuration =
      Duration(minutes: 2);

  static const Duration secondSearchDuration =
      Duration(minutes: 3);

  static const Duration thirdSearchDuration =
      Duration(minutes: 5);

  static const Duration normalSearchDuration =
      Duration(minutes: 2);

  // ============================================================
  // INTERNAL STATE
  // ============================================================

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  String? _activeRequestId;

  // ============================================================
  // GETTERS
  // ============================================================

  String? get activeRequestId => _activeRequestId;

  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await clearActiveRequest();
  }

  // ============================================================
  // SEARCH DURATION
  // ============================================================

  Future<Duration> getNextSearchDuration({
    required String ownerId,
  }) async {
    final int count = await getTodaySearchCount(
      ownerId: ownerId,
    );

    return _durationForSearchNumber(count + 1);
  }

  Duration _durationForSearchNumber(
    int searchNumber,
  ) {
    switch (searchNumber) {
      case 1:
        return firstSearchDuration;
      case 2:
        return secondSearchDuration;
      case 3:
        return thirdSearchDuration;
      default:
        return normalSearchDuration;
    }
  }

  // ============================================================
  // TODAY SEARCH COUNT
  // ============================================================

  Future<int> getTodaySearchCount({
    required String ownerId,
  }) async {
    final User? user = _auth.currentUser;
    final String cleanOwnerId = ownerId.trim();

    if (user == null || cleanOwnerId.isEmpty) {
      return 0;
    }

    final DateTime now = DateTime.now();

    final DateTime startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .where(
                'ownerAuthUid',
                isEqualTo: user.uid,
              )
              .where(
                'searchType',
                isEqualTo: 'insta_walk',
              )
              .where(
                'createdAt',
                isGreaterThanOrEqualTo:
                    Timestamp.fromDate(startOfDay),
              )
              .get();

      int count = 0;

      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic> data = doc.data();

        final String savedOwnerId =
            data['ownerId']?.toString().trim() ?? '';

        if (savedOwnerId == cleanOwnerId) {
          count++;
        }
      }

      return count;
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'getTodaySearchCount',
        e,
      );
      return 0;
    } catch (e) {
      _logError(
        'getTodaySearchCount',
        e,
      );
      return 0;
    }
  }

  // ============================================================
  // FIND OWNER PROFILE
  // ============================================================

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      findOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
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
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'findOwnerProfile',
        e,
      );
      rethrow;
    } catch (e) {
      _logError(
        'findOwnerProfile',
        e,
      );
      rethrow;
    }
  }

  // ============================================================
  // FIND ACTIVE REQUEST
  // ============================================================

  Future<InstaWalkRequestState?> findActiveRequest({
    required String ownerId,
  }) async {
    final User? user = _auth.currentUser;
    final String cleanOwnerId = ownerId.trim();

    if (user == null || cleanOwnerId.isEmpty) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .where(
                'ownerAuthUid',
                isEqualTo: user.uid,
              )
              .where(
                'ownerId',
                isEqualTo: cleanOwnerId,
              )
              .where(
                'searchType',
                isEqualTo: 'insta_walk',
              )
              .where(
                'status',
                isEqualTo: 'searching',
              )
              .orderBy(
                'createdAt',
                descending: true,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final QueryDocumentSnapshot<Map<String, dynamic>> doc =
          snapshot.docs.first;

      final Map<String, dynamic> data = doc.data();

      final DateTime? expiresAt =
          _readExpiresAt(data);

      if (expiresAt != null &&
          !DateTime.now().isBefore(expiresAt)) {
        await _markExpiredIfSearching(
          requestId: doc.id,
        );

        return InstaWalkRequestState(
          status: InstaWalkRequestStatus.expired,
          data: data,
        );
      }

      _activeRequestId = doc.id;

      return InstaWalkRequestState(
        status: InstaWalkRequestStatus.searching,
        data: data,
      );
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'findActiveRequest',
        e,
      );
      return null;
    } catch (e) {
      _logError(
        'findActiveRequest',
        e,
      );
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
    required GeoPoint ownerLocation,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const InstaWalkSearchResult.failure(
        message: 'Please login first.',
      );
    }

    final String cleanOwnerId = ownerId.trim();

    final String cleanOwnerName =
        ownerName.trim().isEmpty
            ? 'Dog Owner'
            : ownerName.trim();

    final String cleanAddress = address.trim();

    if (cleanOwnerId.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner ID is missing.',
      );
    }

    if (cleanAddress.isEmpty) {
      return const InstaWalkSearchResult.failure(
        message: 'Owner address is missing.',
      );
    }

    // ==========================================================
    // EXISTING REQUEST
    // ==========================================================

    if (hasActiveRequest) {
      final String activeId = _activeRequestId!;

      final InstaWalkRequestState state =
          await getRequestState(activeId);

      if (state.isSearching) {
        final DateTime? existingExpiry =
            state.expiresAt;

        if (existingExpiry == null) {
          await clearActiveRequest();
        } else {
          Duration remaining =
              existingExpiry.difference(
            DateTime.now(),
          );

          if (remaining.isNegative) {
            remaining = Duration.zero;
          }

          return InstaWalkSearchResult.success(
            requestId: activeId,
            expiresAt: existingExpiry,
            duration: remaining,
            searchNumber: state.searchNumber,
          );
        }
      }

      if (state.isAccepted) {
        return InstaWalkSearchResult.success(
          requestId: activeId,
          expiresAt:
              state.expiresAt ??
                  DateTime.now(),
          duration: Duration.zero,
          searchNumber: state.searchNumber,
        );
      }

      await clearActiveRequest();
    }

    try {
      await _requestSubscription?.cancel();
      _requestSubscription = null;

      final int todayCount =
          await getTodaySearchCount(
        ownerId: cleanOwnerId,
      );

      final int searchNumber =
          todayCount + 1;

      final Duration duration =
          _durationForSearchNumber(
        searchNumber,
      );

      final DocumentReference<Map<String, dynamic>> ref =
          _firestore
              .collection(walkRequestsCollection)
              .doc();

      final DateTime now =
          DateTime.now();

      final DateTime expiresAt =
          now.add(duration);

      await ref.set({
        // ======================================================
        // REQUEST
        // ======================================================

        'requestId': ref.id,

        // ======================================================
        // STATUS
        // ======================================================

        'status': 'searching',

        // ======================================================
        // TYPE
        // ======================================================

        'searchType': 'insta_walk',
        'senderRole': 'owner',

        // ======================================================
        // OWNER
        // ======================================================

        'senderUid': user.uid,
        'ownerId': cleanOwnerId,
        'ownerAuthUid': user.uid,
        'ownerName': cleanOwnerName,

        // ======================================================
        // ADDRESS
        // ======================================================

        'address': cleanAddress,

        // ======================================================
        // SEARCH
        // ======================================================

        'searchRadiusKm': searchRadiusKm,
        'searchNumber': searchNumber,
        'searchDurationSeconds':
            duration.inSeconds,

        // ======================================================
        // LOCATION
        // ======================================================

        'ownerLocation': ownerLocation,
        'ownerLocationType': 'search_snapshot',

        // ======================================================
        // WALKER
        // ======================================================

        'walkerUid': null,
        'walkerId': null,
        'walkerName': null,
        'acceptedBy': null,
        'acceptedAt': null,

        // ======================================================
        // TIME
        // ======================================================

        'createdAt':
            FieldValue.serverTimestamp(),

        'expiresAt':
            Timestamp.fromDate(expiresAt),
      });

      _activeRequestId = ref.id;

      return InstaWalkSearchResult.success(
        requestId: ref.id,
        expiresAt: expiresAt,
        duration: duration,
        searchNumber: searchNumber,
      );
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'startSearch',
        e,
      );

      return InstaWalkSearchResult.failure(
        message: _firebaseErrorMessage(e),
        errorCode: e.code,
      );
    } catch (e) {
      _logError(
        'startSearch',
        e,
      );

      return const InstaWalkSearchResult.failure(
        message:
            'Unable to start Insta Walk search.',
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
    void Function(Object error)? onError,
  }) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return;
    }

    await _requestSubscription?.cancel();

    _activeRequestId = id;

    bool acceptedSent = false;
    bool expiredSent = false;
    bool cancelledSent = false;

    final DocumentReference<Map<String, dynamic>> ref =
        _firestore
            .collection(walkRequestsCollection)
            .doc(id);

    _requestSubscription = ref.snapshots().listen(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
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

        if (status == 'accepted') {
          if (acceptedSent) {
            return;
          }

          acceptedSent = true;

          onAccepted(
            InstaWalkAcceptedData.fromMap(
              data,
            ),
          );

          return;
        }

        if (status == 'expired') {
          if (expiredSent) {
            return;
          }

          expiredSent = true;

          onExpired?.call();

          return;
        }

        if (status == 'cancelled' ||
            status == 'owner_cancelled' ||
            status == 'walker_cancelled') {
          if (cancelledSent) {
            return;
          }

          cancelledSent = true;

          onCancelled?.call();
        }
      },
      onError: (Object error) {
        onError?.call(error);
      },
    );
  }

  // ============================================================
  // GET REQUEST STATE
  // ============================================================

  Future<InstaWalkRequestState> getRequestState(
    String requestId,
  ) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return const InstaWalkRequestState(
        status: InstaWalkRequestStatus.notFound,
      );
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .doc(id)
              .get();

      if (!snapshot.exists ||
          snapshot.data() == null) {
        if (_activeRequestId == id) {
          _activeRequestId = null;
        }

        return const InstaWalkRequestState(
          status: InstaWalkRequestStatus.notFound,
        );
      }

      final Map<String, dynamic> data =
          snapshot.data()!;

      final String status =
          data['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (status == 'searching') {
        final DateTime? expiresAt =
            _readExpiresAt(data);

        if (expiresAt != null &&
            !DateTime.now().isBefore(expiresAt)) {
          await _markExpiredIfSearching(
            requestId: id,
          );

          if (_activeRequestId == id) {
            _activeRequestId = null;
          }

          return InstaWalkRequestState(
            status:
                InstaWalkRequestStatus.expired,
            data: data,
          );
        }

        _activeRequestId = id;

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.searching,
          data: data,
        );
      }

      if (status == 'accepted') {
        _activeRequestId = id;

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.accepted,
          data: data,
        );
      }

      if (status == 'expired') {
        if (_activeRequestId == id) {
          _activeRequestId = null;
        }

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.expired,
          data: data,
        );
      }

      if (status == 'cancelled' ||
          status == 'owner_cancelled' ||
          status == 'walker_cancelled') {
        if (_activeRequestId == id) {
          _activeRequestId = null;
        }

        return InstaWalkRequestState(
          status:
              InstaWalkRequestStatus.cancelled,
          data: data,
        );
      }

      return InstaWalkRequestState(
        status:
            InstaWalkRequestStatus.unknown,
        data: data,
      );
    } on FirebaseException catch (e) {
      return InstaWalkRequestState(
        status: InstaWalkRequestStatus.error,
        errorMessage:
            _firebaseErrorMessage(e),
      );
    } catch (_) {
      return const InstaWalkRequestState(
        status: InstaWalkRequestStatus.error,
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
      final DocumentReference<Map<String, dynamic>> ref =
          _firestore
              .collection(walkRequestsCollection)
              .doc(id.trim());

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await ref.get();

      if (!snapshot.exists) {
        await clearActiveRequest();
        return false;
      }

      final String status =
          snapshot.data()?['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (status == 'accepted') {
        return false;
      }

      if (status != 'searching') {
        await clearActiveRequest();
        return false;
      }

      await ref.update({
        'status': 'owner_cancelled',
        'cancelledAt':
            FieldValue.serverTimestamp(),
        'cancelledBy': 'owner',
      });

      await clearActiveRequest();

      return true;
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'cancelSearch',
        e,
      );
      return false;
    } catch (e) {
      _logError(
        'cancelSearch',
        e,
      );
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
      final DocumentReference<Map<String, dynamic>> ref =
          _firestore
              .collection(walkRequestsCollection)
              .doc(id.trim());

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await ref.get();

      if (!snapshot.exists) {
        await clearActiveRequest();
        return false;
      }

      final Map<String, dynamic> data =
          snapshot.data() ?? {};

      final String status =
          data['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (status == 'accepted') {
        return false;
      }

      if (status != 'searching') {
        await clearActiveRequest();
        return false;
      }

      final DateTime? expiresAt =
          _readExpiresAt(data);

      if (expiresAt != null &&
          DateTime.now().isBefore(expiresAt)) {
        return false;
      }

      await ref.update({
        'status': 'expired',
        'expiredAt':
            FieldValue.serverTimestamp(),
      });

      await clearActiveRequest();

      return true;
    } on FirebaseException catch (e) {
      _logFirebaseError(
        'expireRequest',
        e,
      );
      return false;
    } catch (e) {
      _logError(
        'expireRequest',
        e,
      );
      return false;
    }
  }

  // ============================================================
  // REMAINING TIME
  // ============================================================

  Future<Duration?> getRemainingTime(
    String requestId,
  ) async {
    final InstaWalkRequestState state =
        await getRequestState(requestId);

    if (!state.isSearching ||
        state.expiresAt == null) {
      return null;
    }

    final Duration remaining =
        state.expiresAt!.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      return Duration.zero;
    }

    return remaining;
  }

  // ============================================================
  // CLEAR ACTIVE REQUEST
  // ============================================================

  Future<void> clearActiveRequest() async {
    await _requestSubscription?.cancel();

    _requestSubscription = null;
    _activeRequestId = null;
  }

  // ============================================================
  // MARK EXPIRED
  // ============================================================

  Future<void> _markExpiredIfSearching({
    required String requestId,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref =
          _firestore
              .collection(walkRequestsCollection)
              .doc(requestId.trim());

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await ref.get();

      if (!snapshot.exists) {
        return;
      }

      final Map<String, dynamic> data =
          snapshot.data() ?? {};

      final String status =
          data['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (status != 'searching') {
        return;
      }

      final DateTime? expiresAt =
          _readExpiresAt(data);

      if (expiresAt != null &&
          DateTime.now().isBefore(expiresAt)) {
        return;
      }

      await ref.update({
        'status': 'expired',
        'expiredAt':
            FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      _logFirebaseError(
        '_markExpiredIfSearching',
        e,
      );
    } catch (e) {
      _logError(
        '_markExpiredIfSearching',
        e,
      );
    }
  }

  // ============================================================
  // READ EXPIRY
  // ============================================================

  DateTime? _readExpiresAt(
    Map<String, dynamic> data,
  ) {
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

      case 'unauthenticated':
        return 'Please login again.';

      case 'not-found':
        return 'Walk request was not found.';

      default:
        return 'Unable to process Insta Walk request.';
    }
  }

  // ============================================================
  // LOGGING
  // ============================================================

  void _logFirebaseError(
    String method,
    FirebaseException error,
  ) {
    // ignore: avoid_print
    print(
      'InstaWalkSearchService.$method '
      'FirebaseException: '
      '${error.code} - ${error.message}',
    );
  }

  void _logError(
    String method,
    Object error,
  ) {
    // ignore: avoid_print
    print(
      'InstaWalkSearchService.$method '
      'error: $error',
    );
  }
}

// ==================================================================
// SEARCH RESULT
// ==================================================================

class InstaWalkSearchResult {
  final bool success;
  final String? requestId;
  final DateTime? expiresAt;
  final Duration? duration;
  final int? searchNumber;
  final String? message;
  final String? errorCode;

  const InstaWalkSearchResult({
    required this.success,
    this.requestId,
    this.expiresAt,
    this.duration,
    this.searchNumber,
    this.message,
    this.errorCode,
  });

  const InstaWalkSearchResult.success({
    required String requestId,
    required DateTime expiresAt,
    required Duration duration,
    int? searchNumber,
  }) : this(
          success: true,
          requestId: requestId,
          expiresAt: expiresAt,
          duration: duration,
          searchNumber: searchNumber,
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

// ==================================================================
// ACCEPTED DATA
// ==================================================================

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
    DateTime? acceptedAt;

    final dynamic acceptedValue =
        data['acceptedAt'];

    if (acceptedValue is Timestamp) {
      acceptedAt =
          acceptedValue.toDate();
    } else if (acceptedValue is DateTime) {
      acceptedAt = acceptedValue;
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

      walkerUid: walkerUid,

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

      acceptedAt: acceptedAt,

      rawData:
          Map<String, dynamic>.from(data),
    );
  }

  bool get hasWalker =>
      walkerUid.isNotEmpty;
}

// ==================================================================
// REQUEST STATUS
// ==================================================================

enum InstaWalkRequestStatus {
  searching,
  accepted,
  expired,
  cancelled,
  notFound,
  unknown,
  error,
}

// ==================================================================
// REQUEST STATE
// ==================================================================

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

  int? get searchNumber {
    final dynamic value =
        data?['searchNumber'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  String get statusText {
    switch (status) {
      case InstaWalkRequestStatus.searching:
        return 'Searching';

      case InstaWalkRequestStatus.accepted:
        return 'Accepted';

      case InstaWalkRequestStatus.expired:
        return 'Expired';

      case InstaWalkRequestStatus.cancelled:
        return 'Cancelled';

      case InstaWalkRequestStatus.notFound:
        return 'Not Found';

      case InstaWalkRequestStatus.unknown:
        return 'Unknown';

      case InstaWalkRequestStatus.error:
        return 'Error';
    }
  }
}
