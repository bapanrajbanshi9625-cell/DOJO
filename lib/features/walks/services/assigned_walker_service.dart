import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/assigned_walker.dart';

class AssignedWalkerService {
  AssignedWalkerService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // OWNER BUSINESS ID → ASSIGNED WALKER BUSINESS ID
  // ============================================================

  static Stream<AssignedWalker?> watchAssignedWalker(
    String ownerId,
  ) {
    final String normalizedOwnerId = ownerId.trim();

    if (normalizedOwnerId.isEmpty) {
      return Stream<AssignedWalker?>.value(null);
    }

    return _firestore
        .collection('walk_requests')
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

      final DocumentSnapshot<Map<String, dynamic>> doc =
          snapshot.docs.first;

      final Map<String, dynamic> data =
          doc.data() ?? <String, dynamic>{};

      return AssignedWalker.fromFirestore(
        doc.id,
        data,
      );
    });
  }
}
