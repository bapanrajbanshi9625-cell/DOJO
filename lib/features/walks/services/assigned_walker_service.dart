import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/assigned_walker.dart';

class AssignedWalkerService {
  AssignedWalkerService._();

  static final AssignedWalkerService instance =
      AssignedWalkerService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Stream<AssignedWalker?> assignedWalkerStream() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream<AssignedWalker?>.value(null);
    }

    return _firestore
        .collection('walk_requests')
        .where(
          'ownerUid',
          isEqualTo: user.uid,
        )
        .where(
          'status',
          whereIn: [
            'accepted',
            'assigned',
            'on_the_way',
            'arrived',
          ],
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final doc = snapshot.docs.first;

          return AssignedWalker.fromFirestore(
            doc.id,
            doc.data(),
          );
        });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      walkStream(String walkId) {
    return _firestore
        .collection('walk_requests')
        .doc(walkId)
        .snapshots();
  }
}
