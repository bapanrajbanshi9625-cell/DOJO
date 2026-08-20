import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveWalkService {
  ActiveWalkService._();

  static final ActiveWalkService instance =
      ActiveWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================================
  // ACTIVE WALK COLLECTION
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _activeWalks =>
          _firestore.collection('active_walk');

  // ==========================================================
  // GET ACTIVE WALKS FOR OWNER
  //
  // active_walk = walker is on the way.
  //
  // This collection does NOT contain:
  // peeCount
  // poopCount
  // routeCoordinates
  // events
  // elapsedSeconds
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchActiveWalks({
    required String ownerId,
  }) {
    return _activeWalks
        .where(
          'ownerId',
          isEqualTo: ownerId,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .snapshots();
  }

  // ==========================================================
  // GET ONE ACTIVE WALK
  // ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchActiveWalk({
    required String documentId,
  }) {
    return _activeWalks
        .doc(documentId)
        .snapshots();
  }

  // ==========================================================
  // FIND ACTIVE WALK BY WALK ID
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchActiveWalkByWalkId({
    required String walkId,
  }) {
    return _activeWalks
        .where(
          'walkId',
          isEqualTo: walkId,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .limit(1)
        .snapshots();
  }

  // ==========================================================
  // GET ACTIVE WALK ONCE
  // ==========================================================

  Future<QuerySnapshot<Map<String, dynamic>>>
      getActiveWalk({
    required String ownerId,
  }) {
    return _activeWalks
        .where(
          'ownerId',
          isEqualTo: ownerId,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .limit(1)
        .get();
  }

  // ==========================================================
  // CANCEL / CLOSE ACTIVE WALK
  //
  // This only changes the status.
  // It does NOT create or modify liveWalkSessions.
  // ==========================================================

  Future<void> closeActiveWalk({
    required String documentId,
  }) async {
    await _activeWalks
        .doc(documentId)
        .update({
      'status': 'closed',
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ==========================================================
  // DELETE ACTIVE WALK
  //
  // Use only when the active_walk document should
  // completely disappear.
  // ==========================================================

  Future<void> deleteActiveWalk({
    required String documentId,
  }) async {
    await _activeWalks
        .doc(documentId)
        .delete();
  }
}
