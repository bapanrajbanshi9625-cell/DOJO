import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalkChatService {
  WalkChatService._();

  static final WalkChatService instance =
      WalkChatService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>>
      messagesStream(String walkId) {
    return _firestore
        .collection('walk_requests')
        .doc(walkId)
        .collection('messages')
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots();
  }

  Future<void> sendTextMessage({
    required String walkId,
    required String text,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final String cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    await _firestore
        .collection('walk_requests')
        .doc(walkId)
        .collection('messages')
        .add({
      'senderUid': user.uid,
      'senderRole': 'owner',
      'type': 'text',
      'text': cleanText,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendVoiceMessage({
    required String walkId,
    required String audioUrl,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    await _firestore
        .collection('walk_requests')
        .doc(walkId)
        .collection('messages')
        .add({
      'senderUid': user.uid,
      'senderRole': 'owner',
      'type': 'voice',
      'audioUrl': audioUrl,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }
}
