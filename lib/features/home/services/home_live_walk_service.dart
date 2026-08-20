import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeLiveWalkService {
  HomeLiveWalkService._();

  static final HomeLiveWalkService instance =
      HomeLiveWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>>
      liveWalkStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    final ownerUid = user.uid.trim();

    if (ownerUid.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('active_walks')
        .where(
          'ownerUid',
          isEqualTo: ownerUid,
        )
        .snapshots();
  }

  bool isLiveWalk(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    for (final document in snapshot.docs) {
      final data = document.data();

      final dynamic status =
          data['status'];

      final dynamic walkStatus =
          data['walkStatus'];

      final dynamic live =
          data['live'];

      final dynamic isLive =
          data['isLive'];

      if (status is String &&
          status.trim().toLowerCase() == 'live') {
        return true;
      }

      if (walkStatus is String &&
          walkStatus.trim().toLowerCase() == 'live') {
        return true;
      }

      if (live == true || isLive == true) {
        return true;
      }
    }

    return false;
  }

  Map<String, dynamic>? getLiveWalkData(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    for (final document in snapshot.docs) {
      final data = document.data();

      final dynamic status =
          data['status'];

      final dynamic walkStatus =
          data['walkStatus'];

      final dynamic live =
          data['live'];

      final dynamic isLive =
          data['isLive'];

      final bool liveFound =
          (status is String &&
              status.trim().toLowerCase() == 'live') ||
          (walkStatus is String &&
              walkStatus.trim().toLowerCase() == 'live') ||
          live == true ||
          isLive == true;

      if (liveFound) {
        return {
          ...data,
          '_documentId': document.id,
        };
      }
    }

    return null;
  }
}
