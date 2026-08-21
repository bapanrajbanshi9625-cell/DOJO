// File location:
// lib/features/home/services/home_live_walk_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// DOJO WALKER
/// HOME LIVE WALK SERVICE
/// ============================================================
///
/// Owner Home Screen पर current active/live walk detect करता है.
///
/// FIRESTORE SOURCE OF TRUTH:
///
/// active_walk
///
/// IMPORTANT:
/// Walker side का LiveWalkBackgroundService भी इसी collection
/// में location/status update करता है.
///
/// Supported active statuses:
/// - active
/// - live
/// - accepted
///
/// Owner UID:
/// - ownerUid
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
  //
  // IMPORTANT:
  //
  // Do NOT change this to active_walks.
  //
  // Walker background service:
  //     active_walk
  //
  // App state service:
  //     active_walk
  //
  // इसलिए Owner भी यही collection पढ़ेगा.
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _activeWalks =>
          _firestore.collection('active_walk');

  // ============================================================
  // OWNER LIVE WALK STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      liveWalkStream() {
    final User? user =
        _auth.currentUser;

    // ----------------------------------------------------------
    // User not logged in
    // ----------------------------------------------------------

    if (user == null) {
      return const Stream.empty();
    }

    final String ownerUid =
        user.uid.trim();

    if (ownerUid.isEmpty) {
      return const Stream.empty();
    }

    // ----------------------------------------------------------
    // OWNER'S ACTIVE WALK
    // ----------------------------------------------------------
    //
    // We intentionally query only ownerUid here.
    //
    // Status filtering is done locally so that:
    //
    // active
    // live
    // accepted
    //
    // सभी compatible रहें.
    //
    // इससे Firestore query/index problems भी कम होंगे.
    // ----------------------------------------------------------

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
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      if (_isActiveWalk(data)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // GET LIVE WALK DATA
  // ============================================================

  Map<String, dynamic>? getLiveWalkData(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    // ----------------------------------------------------------
    // Prefer ACTIVE / LIVE walk.
    // ----------------------------------------------------------

    Map<String, dynamic>? fallback;

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      if (!_isActiveWalk(data)) {
        continue;
      }

      final Map<String, dynamic> result =
          <String, dynamic>{
        ...data,

        // ------------------------------------------------------
        // Always expose Firestore document ID.
        // ------------------------------------------------------

        '_documentId': document.id,

        // ------------------------------------------------------
        // Ensure walkId is available.
        // ------------------------------------------------------

        if (!_hasValue(data['walkId']))
          'walkId': document.id,
      };

      // --------------------------------------------------------
      // ACTIVE is preferred over ACCEPTED.
      // --------------------------------------------------------

      final String status =
          _readStatus(data);

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
    // STATUS
    // ----------------------------------------------------------

    final String status =
        _readStatus(data);

    if (status == 'active' ||
        status == 'live') {
      return true;
    }

    // ----------------------------------------------------------
    // WALK STATUS
    // ----------------------------------------------------------

    final String walkStatus =
        _readString(
      data['walkStatus'],
    ).toLowerCase();

    if (walkStatus == 'active' ||
        walkStatus == 'live') {
      return true;
    }

    // ----------------------------------------------------------
    // BOOLEAN FLAGS
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
