import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/assigned_walker.dart';

class AssignedWalkerService {
  AssignedWalkerService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Stream<AssignedWalker?> watchAssignedWalker(
    String ownerUid,
  ) {
    return _firestore
        .collection('walk_requests')
        .where(
          'ownerUid',
          isEqualTo: ownerUid,
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

      final data = snapshot.docs.first.data();

      return AssignedWalker.fromFirestore(data);
    });
  }
}
