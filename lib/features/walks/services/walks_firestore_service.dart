import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/walk_model.dart';

class WalksFirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Stream<List<WalkModel>> watchOwnerWalks() async* {
    final user = _auth.currentUser;

    if (user == null) {
      yield [];
      return;
    }

    try {
      // Firebase UID सिर्फ identity mapping के लिए।
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      final String ownerId =
          data?['Owner ID']?.toString().trim() ?? '';

      if (ownerId.isEmpty) {
        yield [];
        return;
      }

      await for (final snapshot in _firestore
          .collection('walks')
          .where(
            'ownerId',
            isEqualTo: ownerId,
          )
          .snapshots()) {
        final walks = snapshot.docs
            .map(WalkModel.fromFirestore)
            .toList();

        walks.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        yield walks;
      }
    } catch (_) {
      yield [];
    }
  }
}
