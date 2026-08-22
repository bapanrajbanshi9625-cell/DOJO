import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalkRequestService {
  WalkRequestService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static const String walkRequestsCollection = 'walk_requests';

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

    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('User is not authenticated.');
    }

    await _firestore
        .collection(walkRequestsCollection)
        .doc(id)
        .update({
      'status': 'walker_on_way',
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedByAuthUid': user.uid,
      'updatedByRole': 'walker',
    });
  }

  // ============================================================
  // SEND MESSAGE
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

    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('User is not authenticated.');
    }

    // ------------------------------------------------------------
    // IMPORTANT
    //
    // ownerId / walkerId = Business IDs
    // senderAuthUid      = Firebase Authentication UID
    //
    // Phone number is NOT used as identity.
    // ------------------------------------------------------------

    String senderRole = 'unknown';

    if (owner == walker) {
      senderRole = 'owner';
    } else {
      // Determine sender using the authenticated UID from
      // the parent walk request.
      final DocumentSnapshot<Map<String, dynamic>> requestDoc =
          await _firestore
              .collection(walkRequestsCollection)
              .doc(request)
              .get();

      final Map<String, dynamic> requestData =
          requestDoc.data() ?? <String, dynamic>{};

      final String ownerAuthUid =
          requestData['ownerAuthUid']
                  ?.toString()
                  .trim() ??
              '';

      final String walkerAuthUid =
          requestData['walkerUid']
                  ?.toString()
                  .trim() ??
              '';

      if (user.uid == ownerAuthUid) {
        senderRole = 'owner';
      } else if (user.uid == walkerAuthUid) {
        senderRole = 'walker';
      }
    }

    await _firestore
        .collection(walkRequestsCollection)
        .doc(request)
        .collection('messages')
        .add({
      // ----------------------------------------------------------
      // BUSINESS IDS
      // ----------------------------------------------------------

      'ownerId': owner,
      'walkerId': walker,

      // ----------------------------------------------------------
      // FIREBASE AUTH ID
      // ----------------------------------------------------------

      'senderAuthUid': user.uid,

      // ----------------------------------------------------------
      // MESSAGE
      // ----------------------------------------------------------

      'senderId': senderRole == 'walker'
          ? walker
          : owner,

      'receiverId': senderRole == 'walker'
          ? owner
          : walker,

      'senderRole': senderRole,

      'message': text,
      'type': 'text',

      // ----------------------------------------------------------
      // TIME
      // ----------------------------------------------------------

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
        .collection(walkRequestsCollection)
        .doc(id)
        .collection('messages')
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots();
  }

  // ============================================================
  // WATCH REQUEST
  // ============================================================

  static Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchRequest(
    String requestId,
  ) {
    final String id = requestId.trim();

    if (id.isEmpty) {
      return const Stream<
          DocumentSnapshot<Map<String, dynamic>>>.empty();
    }

    return _firestore
        .collection(walkRequestsCollection)
        .doc(id)
        .snapshots();
  }

  // ============================================================
  // GET REQUEST
  // ============================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>>
      getRequest(
    String requestId,
  ) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      throw ArgumentError('requestId cannot be empty.');
    }

    return _firestore
        .collection(walkRequestsCollection)
        .doc(id)
        .get();
  }

  // ============================================================
  // ACCEPT REQUEST
  //
  // walkerId      = Business Walker ID
  // walkerAuthUid = Firebase UID
  // ============================================================

  static Future<void> acceptRequest({
    required String requestId,
    required String walkerId,
    required String walkerName,
  }) async {
    final String request = requestId.trim();
    final String businessWalkerId = walkerId.trim();
    final String name = walkerName.trim();

    if (request.isEmpty) {
      throw ArgumentError('requestId cannot be empty.');
    }

    if (businessWalkerId.isEmpty) {
      throw ArgumentError('walkerId cannot be empty.');
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('Walker is not authenticated.');
    }

    final DocumentReference<Map<String, dynamic>> ref =
        _firestore
            .collection(walkRequestsCollection)
            .doc(request);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await ref.get();

    if (!snapshot.exists) {
      throw StateError('Walk request not found.');
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    final String status =
        data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status != 'searching') {
      throw StateError(
        'This walk request is no longer available.',
      );
    }

    await ref.update({
      // ----------------------------------------------------------
      // STATUS
      // ----------------------------------------------------------

      'status': 'accepted',

      // ----------------------------------------------------------
      // WALKER BUSINESS ID
      // ----------------------------------------------------------

      'walkerId': businessWalkerId,

      // ----------------------------------------------------------
      // WALKER FIREBASE UID
      // ----------------------------------------------------------

      'walkerUid': user.uid,

      // ----------------------------------------------------------
      // WALKER DETAILS
      // ----------------------------------------------------------

      'walkerName': name.isEmpty ? 'Walker' : name,

      // ----------------------------------------------------------
      // ACCEPTED BY
      //
      // Keep acceptedBy for backward compatibility.
      // It stores Firebase UID.
      // ----------------------------------------------------------

      'acceptedBy': user.uid,

      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // CANCEL REQUEST
  // ============================================================

  static Future<void> cancelRequest({
    required String requestId,
    required String cancelledBy,
  }) async {
    final String id = requestId.trim();
    final String role = cancelledBy.trim().toLowerCase();

    if (id.isEmpty) {
      throw ArgumentError('requestId cannot be empty.');
    }

    if (role.isEmpty) {
      throw ArgumentError('cancelledBy cannot be empty.');
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('User is not authenticated.');
    }

    String status;

    if (role == 'owner') {
      status = 'owner_cancelled';
    } else if (role == 'walker') {
      status = 'walker_cancelled';
    } else {
      status = 'cancelled';
    }

    await _firestore
        .collection(walkRequestsCollection)
        .doc(id)
        .update({
      'status': status,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': role,
      'cancelledByAuthUid': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // COMPLETE WALK
  // ============================================================

  static Future<void> completeWalk(
    String requestId,
  ) async {
    final String id = requestId.trim();

    if (id.isEmpty) {
      throw ArgumentError('requestId cannot be empty.');
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError('User is not authenticated.');
    }

    await _firestore
        .collection(walkRequestsCollection)
        .doc(id)
        .update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'completedByAuthUid': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // BUSINESS ID HELPERS
  // ============================================================

  /// Reads the Owner Business ID from a walk request.
  static String getOwnerId(
    Map<String, dynamic> data,
  ) {
    return data['ownerId']
            ?.toString()
            .trim() ??
        '';
  }

  /// Reads the Walker Business ID from a walk request.
  static String getWalkerId(
    Map<String, dynamic> data,
  ) {
    return data['walkerId']
            ?.toString()
            .trim() ??
        '';
  }

  /// Reads the Owner Firebase UID.
  static String getOwnerAuthUid(
    Map<String, dynamic> data,
  ) {
    return data['ownerAuthUid']
            ?.toString()
            .trim() ??
        '';
  }

  /// Reads the Walker Firebase UID.
  static String getWalkerAuthUid(
    Map<String, dynamic> data,
  ) {
    return data['walkerUid']
            ?.toString()
            .trim() ??
        '';
  }
}
