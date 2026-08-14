import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/walk_model.dart';

class WalksFirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Stream<List<WalkModel>> watchOwnerWalks() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('walks')
        .where(
          'ownerUid',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
          (snapshot) {
            final walks = snapshot.docs
                .map(
                  WalkModel.fromFirestore,
                )
                .toList();

            walks.sort(
              (a, b) =>
                  b.date.compareTo(a.date),
            );

            return walks;
          },
        );
  }
}
