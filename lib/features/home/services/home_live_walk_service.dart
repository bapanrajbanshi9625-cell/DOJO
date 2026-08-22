// File location:
// lib/features/home/services/home_live_walk_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// DOJO WALKER
/// HOME LIVE WALK SERVICE
/// ============================================================
///
/// Owner Home Screen के लिए current active/live walk detect करता है.
///
/// FIRESTORE COLLECTION:
///     active_walk
///
/// OWNER FIELD:
///     ownerUid
///
/// LIVE STATUS:
///     active
///     live
///
/// Additional compatibility:
///     walkStatus
///     live == true
///     isLive == true
///     isActive == true
///
/// ============================================================

class HomeLiveWalkService {
  HomeLiveWalkService._();

  static final HomeLiveWalkService instance =
      HomeLiveWalkService._();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  static const String activeWalkCollection =
      'active_walk';

  CollectionReference<Map<String, dynamic>>
      get _activeWalks {
    return _firestore.collection(
      activeWalkCollection,
    );
  }

  // ============================================================
  // OWNER LIVE WALK STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      liveWalkStream() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return Stream<
          QuerySnapshot<Map<String, dynamic>>
      >.empty();
    }

    final String ownerUid =
        user.uid.trim();

    if (ownerUid.isEmpty) {
      return Stream<
          QuerySnapshot<Map<String, dynamic>>
      >.empty();
    }

    return _activeWalks
        .where(
          'ownerUid',
          isEqualTo: ownerUid,
        )
        .snapshots();
  }

  // ============================================================
  // CHECK LIVE WALK
  // ============================================================

  bool isLiveWalk(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    for (
      final QueryDocumentSnapshot<
          Map<String, dynamic>> document
          in snapshot.docs
    ) {
      if (_isActiveWalk(
        document.data(),
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // GET LIVE WALK DATA
  // ============================================================

  Map<String, dynamic>? getLiveWalkData(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    Map<String, dynamic>? fallback;

    for (
      final QueryDocumentSnapshot<
          Map<String, dynamic>> document
          in snapshot.docs
    ) {
      final Map<String, dynamic> data =
          document.data();

      if (!_isActiveWalk(data)) {
        continue;
      }

      final Map<String, dynamic> result =
          <String, dynamic>{
        ...data,
        '_documentId': document.id,
      };

      // --------------------------------------------------------
      // Ensure walkId exists.
      // --------------------------------------------------------

      if (!_hasValue(
        result['walkId'],
      )) {
        result['walkId'] =
            document.id;
      }

      final String status =
          _readStatus(data);

      // --------------------------------------------------------
      // Prefer active/live.
      // --------------------------------------------------------

      if (status == 'active' ||
          status == 'live') {
        return result;
      }

      fallback ??= result;
    }

    return fallback;
  }

  // ============================================================
  // ACTIVE WALK CHECK
  // ============================================================

  bool _isActiveWalk(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // status
    // ----------------------------------------------------------

    final String status =
        _readStatus(data);

    if (status == 'active' ||
        status == 'live') {
      return true;
    }

    // ----------------------------------------------------------
    // boolean flags
    // ----------------------------------------------------------

    if (data['live'] == true ||
        data['isLive'] == true ||
        data['isActive'] == true) {
      return true;
    }

    return false;
  }

  // ============================================================
  // STATUS READER
  // ============================================================

  String _readStatus(
    Map<String, dynamic> data,
  ) {
    final String status =
        _readString(
      data['status'],
    ).toLowerCase();

    if (status.isNotEmpty) {
      return status;
    }

    return _readString(
      data['walkStatus'],
    ).toLowerCase();
  }

  // ============================================================
  // SAFE STRING
  // ============================================================

  String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  // ============================================================
  // HAS VALUE
  // ============================================================

  bool _hasValue(
    dynamic value,
  ) {
    if (value == null) {
      return false;
    }

    return value
        .toString()
        .trim()
        .isNotEmpty;
  }
}
