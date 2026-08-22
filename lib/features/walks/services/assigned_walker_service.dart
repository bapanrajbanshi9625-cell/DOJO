import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/assigned_walker.dart';

class AssignedWalkerService {
  AssignedWalkerService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const String walkRequestsCollection =
      'walk_requests';

  // ============================================================
  // WATCH ASSIGNED WALKER
  // ============================================================
  //
  // IMPORTANT:
  //
  // ownerId      = Business Owner ID
  // ownerAuthUid = Firebase Authentication UID
  //
  // walkerId     = Business Walker ID
  // walkerUid    = Firebase Authentication UID
  //
  // Primary application identity = Business ID
  // Authentication/security     = Firebase UID
  //
  // Phone number is NOT used.
  // ============================================================

  static Stream<AssignedWalker?> watchAssignedWalker(
    String ownerId,
  ) {
    final String normalizedOwnerId =
        ownerId.trim();

    if (normalizedOwnerId.isEmpty) {
      return Stream<AssignedWalker?>.value(null);
    }

    return _firestore
        .collection(walkRequestsCollection)
        .where(
          'ownerId',
          isEqualTo: normalizedOwnerId,
        )
        .where(
          'status',
          isEqualTo: 'accepted',
        )
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }

      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc =
          snapshot.docs.first;

      final Map<String, dynamic> data =
          doc.data();

      return AssignedWalker.fromFirestore(
        doc.id,
        data,
      );
    });
  }

  // ============================================================
  // WATCH ASSIGNED WALKER FOR CURRENT OWNER
  // ============================================================
  //
  // Automatically finds the current user's Business Owner ID
  // from ownerProfiles/{Firebase UID}.
  //
  // This prevents the UI from accidentally passing Firebase UID
  // where Business Owner ID is required.
  // ============================================================

  static Stream<AssignedWalker?> watchCurrentOwnerAssignedWalker() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream<AssignedWalker?>.value(null);
    }

    return _watchCurrentOwner(user.uid);
  }

  static Stream<AssignedWalker?> _watchCurrentOwner(
    String authUid,
  ) async* {
    try {
      final DocumentSnapshot<Map<String, dynamic>> ownerDoc =
          await _firestore
              .collection('ownerProfiles')
              .doc(authUid)
              .get();

      if (!ownerDoc.exists) {
        yield null;
        return;
      }

      final Map<String, dynamic> data =
          ownerDoc.data() ?? <String, dynamic>{};

      final String ownerId =
          data['ownerId']
                  ?.toString()
                  .trim() ??
              '';

      if (ownerId.isEmpty) {
        yield null;
        return;
      }

      await for (final AssignedWalker? walker
          in watchAssignedWalker(ownerId)) {
        yield walker;
      }
    } on FirebaseException {
      yield null;
    } catch (_) {
      yield null;
    }
  }

  // ============================================================
  // GET ASSIGNED WALKER ONCE
  // ============================================================

  static Future<AssignedWalker?> getAssignedWalker(
    String ownerId,
  ) async {
    final String normalizedOwnerId =
        ownerId.trim();

    if (normalizedOwnerId.isEmpty) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _firestore
              .collection(walkRequestsCollection)
              .where(
                'ownerId',
                isEqualTo: normalizedOwnerId,
              )
              .where(
                'status',
                isEqualTo: 'accepted',
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final QueryDocumentSnapshot<
          Map<String, dynamic>> doc =
          snapshot.docs.first;

      return AssignedWalker.fromFirestore(
        doc.id,
        doc.data(),
      );
    } on FirebaseException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // GET CURRENT OWNER ASSIGNED WALKER ONCE
  // ============================================================

  static Future<AssignedWalker?> getCurrentOwnerAssignedWalker()
      async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> ownerDoc =
          await _firestore
              .collection('ownerProfiles')
              .doc(user.uid)
              .get();

      if (!ownerDoc.exists) {
        return null;
      }

      final Map<String, dynamic> data =
          ownerDoc.data() ?? <String, dynamic>{};

      final String ownerId =
          data['ownerId']
                  ?.toString()
                  .trim() ??
              '';

      if (ownerId.isEmpty) {
        return null;
      }

      return getAssignedWalker(ownerId);
    } on FirebaseException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // BUSINESS ID HELPERS
  // ============================================================

  static String getWalkerId(
    Map<String, dynamic> data,
  ) {
    return data['walkerId']
            ?.toString()
            .trim() ??
        '';
  }

  static String getWalkerAuthUid(
    Map<String, dynamic> data,
  ) {
    return data['walkerUid']
            ?.toString()
            .trim() ??
        '';
  }

  static String getOwnerId(
    Map<String, dynamic> data,
  ) {
    return data['ownerId']
            ?.toString()
            .trim() ??
        '';
  }

  static String getOwnerAuthUid(
    Map<String, dynamic> data,
  ) {
    return data['ownerAuthUid']
            ?.toString()
            .trim() ??
        '';
  }
}
