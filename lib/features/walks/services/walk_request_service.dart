import 'package:cloud_firestore/cloud_firestore.dart';

class WalkRequestService {
  WalkRequestService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // WALKER ON WAY
  // ============================================================

  static Future<void> updateWalkerOnWay(
    String requestId,
  ) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      throw ArgumentError('requestId cannot be empty.');
    }

    await _firestore
        .collection('walk_requests')
        .doc(id)
        .update({
      'status': 'walker_on_way',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // SEND MESSAGE
  //
  // BUSINESS ID IS USED FOR PARTICIPANTS
  // ============================================================

  static Future<void> sendMessage({
    required String requestId,
    required String ownerId,
    required String walkerId,
    required String message,
  }) async {
    final String request = requestId.trim();
    final String owner = ownerId.trim();
    final String walker = walkerId.trim();
    final String text = message.trim();

    if (request.isEmpty) {
      throw ArgumentError('requestId cannot be empty.');
    }

    if (owner.isEmpty) {
      throw ArgumentError('ownerId cannot be empty.');
    }

    if (walker.isEmpty) {
      throw ArgumentError('walkerId cannot be empty.');
    }

    if (text.isEmpty) {
      throw ArgumentError('message cannot be empty.');
    }

    await _firestore
        .collection('walk_requests')
        .doc(request)
        .collection('messages')
        .add({
      // BUSINESS IDs
      'senderId': owner,
      'receiverId': walker,

      // Explicit roles make the backend unambiguous.
      'senderRole': 'owner',
      'receiverRole': 'walker',

      'message': text,
      'type': 'text',

      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // WATCH MESSAGES
  // ============================================================

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchMessages(
    String requestId,
  ) {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return const Stream<
          QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection('walk_requests')
        .doc(id)
        .collection('messages')
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots();
  }
}
