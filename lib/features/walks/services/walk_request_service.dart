import 'package:cloud_firestore/cloud_firestore.dart';

class WalkRequestService {
  WalkRequestService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static Future<void> updateWalkerOnWay(
    String requestId,
  ) async {
    await _firestore
        .collection('walk_requests')
        .doc(requestId)
        .update({
      'status': 'walker_on_way',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> sendMessage({
    required String requestId,
    required String ownerUid,
    required String walkerUid,
    required String message,
  }) async {
    await _firestore
        .collection('walk_requests')
        .doc(requestId)
        .collection('messages')
        .add({
      'senderUid': ownerUid,
      'receiverUid': walkerUid,
      'message': message,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      watchMessages(
    String requestId,
  ) {
    return _firestore
        .collection('walk_requests')
        .doc(requestId)
        .collection('messages')
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots();
  }
}
