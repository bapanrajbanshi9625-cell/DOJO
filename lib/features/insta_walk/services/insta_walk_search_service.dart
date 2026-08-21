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

  static const String walkRequestsCollection = 'walk_requests';
  static const String ownerProfilesCollection = 'ownerProfiles';

  static const double searchRadiusKm = 3.0;

  static const Duration firstSearchDuration =
      Duration(minutes: 2);

  static const Duration secondSearchDuration =
      Duration(minutes: 3);

  static const Duration thirdSearchDuration =
      Duration(minutes: 5);

  static const Duration normalSearchDuration =
      Duration(minutes: 2);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  String? _activeRequestId;

  String? get activeRequestId => _activeRequestId;

  bool get hasActiveRequest =>
      _activeRequestId != null &&
      _activeRequestId!.trim().isNotEmpty;

  User? get currentUser => _auth.currentUser;

  Future<void> dispose() async {
    await _requestSubscription?.cancel();
    _requestSubscription = null;
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

    if (count <= 0) {
      return firstSearchDuration;
    }

    if (count == 1) {
      return secondSearchDuration;
    }

    if (count == 2) {
      return thirdSearchDuration;
    }

    return normalSearchDuration;
  }

  // ============================================================
  // TODAY SEARCH COUNT
  // ============================================================

  Future<int> getTodaySearchCount({
    required String ownerId,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null || ownerId.trim().isEmpty) {
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

        if (savedOwnerId == ownerId.trim()) {
          count++;
        }
      }

      return count;
    } catch (_) {
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

    if (hasActiveRequest) {
      final InstaWalkRequestState state =
          await getRequestState(_activeRequestId!);

      if (state.isSearching) {
        return InstaWalkSearchResult.success(
          requestId: _activeRequestId!,
          expiresAt: state.expiresAt ??
              DateTime.now().add(normalSearchDuration),
          duration: state.expiresAt == null
              ? normalSearchDuration
              : state.expiresAt!
                  .difference(DateTime.now()),
        );
      }

      if (state.isAccepted) {
        return InstaWalkSearchResult.success(
          requestId: _activeRequestId!,
          expiresAt: state.expiresAt ?? DateTime.now(),
          duration: Duration.zero,
        );
      }

      _activeRequestId = null;
    }

    try {
      await _requestSubscription?.cancel();
      _requestSubscription = null;

      final Duration duration =
          await getNextSearchDuration(
        ownerId: ownerId,
      );

      final DocumentReference<Map<String, dynamic>> ref =
          _firestore
              .collection(walkRequestsCollection)
              .doc();

      final DateTime now = DateTime.now();
      final DateTime expiresAt = now.add(duration);

      final int searchNumber =
          await getTodaySearchCount(ownerId: ownerId) + 1;

      await ref.set({
        'requestId': ref.id,
        'status': 'searching',
        'searchType': 'insta_walk',
        'senderRole': 'owner',
        'senderUid': user.uid,
        'ownerId': ownerId.trim(),
        'ownerAuthUid': user.uid,
        'ownerName': ownerName.trim().isEmpty
            ? 'Dog Owner'
            : ownerName.trim(),
        'address': address.trim(),
        'searchRadiusKm': searchRadiusKm,
        'searchNumber': searchNumber,
        'searchDurationSeconds': duration.inSeconds,

        // Location snapshot only.
        'ownerLocation': ownerLocation,
        'ownerLocationType': 'search_snapshot',

        'walkerUid': null,
        'walkerId': null,
        'walkerName': null,
        'acceptedBy': null,
        'acceptedAt': null,

        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      _activeRequestId = ref.id;

      return InstaWalkSearchResult.success(
        requestId: ref.id,
        expiresAt: expiresAt,
        duration: duration,
        searchNumber: searchNumber,
      );
    } on FirebaseException catch (e) {
      return InstaWalkSearchResult.failure(
        message: _firebaseErrorMessage(e),
        errorCode: e.code,
      );
    } catch (_) {
      return const InstaWalkSearchResult.failure(
        message: 'Unable to start Insta Walk search.',
      );
    }
  }

  // ============================================================
  // LISTEN
  // ============================================================

  Future<void> listenForRequest({
    required String requestId,
    required void Function(InstaWalkAcceptedData data)
        onAccepted,
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
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data = snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        if (status == 'accepted') {
          if (acceptedSent) {
            return;
          }

          acceptedSent = true;

          onAccepted(
            InstaWalkAcceptedData.fromMap(data),
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
  // GET STATE
  // ============================================================

  Future<InstaWalkRequestState> getRequestState(
    String requestId,
  ) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .doc(requestId.trim())
              .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return const InstaWalkRequestState(
          status: InstaWalkRequestStatus.notFound,
        );
      }

      final Map<String, dynamic> data = snapshot.data()!;

      final String status =
          data['status']?.toString().trim().toLowerCase() ?? '';

      if (status == 'searching') {
        final DateTime? expiresAt = _readExpiresAt(data);

        if (expiresAt != null &&
            !DateTime.now().isBefore(expiresAt)) {
          return InstaWalkRequestState(
            status: InstaWalkRequestStatus.expired,
            data: data,
          );
        }

        return InstaWalkRequestState(
          status: InstaWalkRequestStatus.searching,
          data: data,
        );
      }

      if (status == 'accepted') {
        return InstaWalkRequestState(
          status: InstaWalkRequestStatus.accepted,
          data: data,
        );
      }

      if (status == 'expired') {
        return InstaWalkRequestState(
          status: InstaWalkRequestStatus.expired,
          data: data,
        );
      }

      if (status == 'cancelled' ||
          status == 'owner_cancelled' ||
          status == 'walker_cancelled') {
        return InstaWalkRequestState(
          status: InstaWalkRequestStatus.cancelled,
          data: data,
        );
      }

      return InstaWalkRequestState(
        status: InstaWalkRequestStatus.unknown,
        data: data,
      );
    } on FirebaseException catch (e) {
      return InstaWalkRequestState(
        status: InstaWalkRequestStatus.error,
        errorMessage: _firebaseErrorMessage(e),
      );
    } catch (_) {
      return const InstaWalkRequestState(
        status: InstaWalkRequestStatus.error,
        errorMessage: 'Unable to check walk request.',
      );
    }
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<bool> cancelSearch({
    String? requestId,
  }) async {
    final String? id = requestId ?? _activeRequestId;

    if (id == null || id.trim().isEmpty) {
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
          snapshot.data()?['status']?.toString().toLowerCase() ?? '';

      if (status == 'accepted') {
        return false;
      }

      if (status != 'searching') {
        await clearActiveRequest();
        return false;
      }

      await ref.update({
        'status': 'owner_cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'owner',
      });

      await clearActiveRequest();

      return true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // EXPIRE
  // ============================================================

  Future<bool> expireRequest({
    String? requestId,
  }) async {
    final String? id = requestId ?? _activeRequestId;

    if (id == null || id.trim().isEmpty) {
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
          data['status']?.toString().toLowerCase() ?? '';

      if (status == 'accepted') {
        return false;
      }

      if (status != 'searching') {
        await clearActiveRequest();
        return false;
      }

      final DateTime? expiresAt = _readExpiresAt(data);

      if (expiresAt != null &&
          DateTime.now().isBefore(expiresAt)) {
        return false;
      }

      await ref.update({
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
      });

      await clearActiveRequest();

      return true;
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
    final InstaWalkRequestState state =
        await getRequestState(requestId);

    if (!state.isSearching || state.expiresAt == null) {
      return null;
    }

    final Duration remaining =
        state.expiresAt!.difference(DateTime.now());

    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<void> clearActiveRequest() async {
    await _requestSubscription?.cancel();

    _requestSubscription = null;
    _activeRequestId = null;
  }

  DateTime? _readExpiresAt(
    Map<String, dynamic> data,
  ) {
    final dynamic value = data['expiresAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

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
      default:
        return 'Unable to process Insta Walk request.';
    }
  }
}

// ================================================================
// RESULT
// ================================================================

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

// ================================================================
// ACCEPTED
// ================================================================

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

    final dynamic value = data['acceptedAt'];

    if (value is Timestamp) {
      acceptedAt = value.toDate();
    } else if (value is DateTime) {
      acceptedAt = value;
    }

    final String walkerUid =
        data['walkerUid']?.toString().trim().isNotEmpty == true
            ? data['walkerUid'].toString().trim()
            : data['acceptedBy']?.toString().trim() ?? '';

    return InstaWalkAcceptedData(
      requestId: data['requestId']?.toString().trim() ?? '',
      ownerId: data['ownerId']?.toString().trim() ?? '',
      ownerAuthUid: data['ownerAuthUid']?.toString().trim() ?? '',
      ownerName:
          data['ownerName']?.toString().trim().isNotEmpty == true
              ? data['ownerName'].toString().trim()
              : 'Dog Owner',
      walkerUid: walkerUid,
      walkerId: data['walkerId']?.toString().trim() ?? '',
      walkerName:
          data['walkerName']?.toString().trim().isNotEmpty == true
              ? data['walkerName'].toString().trim()
              : 'Walker',
      acceptedAt: acceptedAt,
      rawData: Map<String, dynamic>.from(data),
    );
  }

  bool get hasWalker => walkerUid.isNotEmpty;
}

// ================================================================
// STATUS
// ================================================================

enum InstaWalkRequestStatus {
  searching,
  accepted,
  expired,
  cancelled,
  notFound,
  unknown,
  error,
}

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
      status == InstaWalkRequestStatus.searching;

  bool get isAccepted =>
      status == InstaWalkRequestStatus.accepted;

  bool get isExpired =>
      status == InstaWalkRequestStatus.expired;

  bool get isCancelled =>
      status == InstaWalkRequestStatus.cancelled;

  String? get requestId {
    final String value =
        data?['requestId']?.toString().trim() ?? '';

    return value.isEmpty ? null : value;
  }

  DateTime? get expiresAt {
    final dynamic value = data?['expiresAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
