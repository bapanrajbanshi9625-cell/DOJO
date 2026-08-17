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

  // ============================================================
  // MESSAGES STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      messagesStream(
    String walkId,
  ) {
    final String id = walkId.trim();

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

  // ============================================================
  // SEND TEXT MESSAGE
  // ============================================================

  Future<void> sendTextMessage({
    required String walkId,
    required String ownerId,
    required String walkerId,
    required String text,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not authenticated.',
      );
    }

    final String requestId =
        walkId.trim();

    final String senderId =
        ownerId.trim();

    final String receiverId =
        walkerId.trim();

    final String cleanText =
        text.trim();

    if (requestId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    if (senderId.isEmpty) {
      throw ArgumentError(
        'ownerId cannot be empty.',
      );
    }

    if (receiverId.isEmpty) {
      throw ArgumentError(
        'walkerId cannot be empty.',
      );
    }

    if (cleanText.isEmpty) {
      return;
    }

    await _firestore
        .collection('walk_requests')
        .doc(requestId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'senderRole': 'owner',
      'type': 'text',
      'text': cleanText,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // SEND VOICE MESSAGE
  // ============================================================

  Future<void> sendVoiceMessage({
    required String walkId,
    required String ownerId,
    required String walkerId,
    required String audioUrl,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User is not authenticated.',
      );
    }

    final String requestId =
        walkId.trim();

    final String senderId =
        ownerId.trim();

    final String receiverId =
        walkerId.trim();

    final String cleanAudioUrl =
        audioUrl.trim();

    if (requestId.isEmpty) {
      throw ArgumentError(
        'walkId cannot be empty.',
      );
    }

    if (senderId.isEmpty) {
      throw ArgumentError(
        'ownerId cannot be empty.',
      );
    }

    if (receiverId.isEmpty) {
      throw ArgumentError(
        'walkerId cannot be empty.',
      );
    }

    if (cleanAudioUrl.isEmpty) {
      throw ArgumentError(
        'audioUrl cannot be empty.',
      );
    }

    await _firestore
        .collection('walk_requests')
        .doc(requestId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'senderRole': 'owner',
      'type': 'voice',
      'audioUrl': cleanAudioUrl,
      'createdAt':
          FieldValue.serverTimestamp(),
    });
  }
}
