import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/walk_model.dart';

class WalksFirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // OWNER WALKS
  //
  // BUSINESS ID IS THE PRIMARY BACKEND KEY.
  // Firebase UID is used only to locate the owner's profile once.
  // ============================================================

  Stream<List<WalkModel>> watchOwnerWalks() async* {
    final User? user = _auth.currentUser;

    if (user == null) {
      yield <WalkModel>[];
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> ownerDoc =
          await _firestore
              .collection('ownerProfiles')
              .doc(user.uid)
              .get();

      if (!ownerDoc.exists) {
        yield <WalkModel>[];
        return;
      }

      final Map<String, dynamic>? data =
          ownerDoc.data();

      final String ownerId =
          data?['ownerId']?.toString().trim() ?? '';

      if (ownerId.isEmpty) {
        yield <WalkModel>[];
        return;
      }

      // ========================================================
      // FROM HERE ON:
      //
      // OWNER BUSINESS ID
      // ========================================================

      await for (final QuerySnapshot<Map<String, dynamic>> snapshot
          in _firestore
              .collection('walks')
              .where(
                'ownerId',
                isEqualTo: ownerId,
              )
              .snapshots()) {
        final List<WalkModel> walks = snapshot.docs
            .map(WalkModel.fromFirestore)
            .toList();

        walks.sort(
          (a, b) => b.date.compareTo(a.date),
        );

        yield walks;
      }
    } catch (_) {
      yield <WalkModel>[];
    }
  }
}
