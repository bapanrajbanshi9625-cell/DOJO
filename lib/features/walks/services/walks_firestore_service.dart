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
      // Firebase UID से Owner Profile खोजें
      final ownerDoc = await _firestore
          .collection('ownerProfiles')
          .doc(user.uid)
          .get();

      final data = ownerDoc.data();

      final String ownerId =
          data?['ownerId']?.toString().trim() ?? '';

      if (ownerId.isEmpty) {
        yield [];
        return;
      }

      // अब Walks में Owner ID से search होगा
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
