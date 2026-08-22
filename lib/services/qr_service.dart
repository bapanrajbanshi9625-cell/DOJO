// lib/services/qr_service.dart

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// QR DATA
/// ============================================================

class QRData {
  final String ownerId;
  final String ownerName;
  final String walkId;
  final String qrPayload;

  const QRData({
    required this.ownerId,
    required this.ownerName,
    required this.walkId,
    required this.qrPayload,
  });

  factory QRData.fromMap(Map<String, dynamic> map) {
    return QRData(
      ownerId: (map['ownerId'] ?? '').toString(),
      ownerName: (map['ownerName'] ?? '').toString(),
      walkId: (map['walkId'] ?? '').toString(),
      qrPayload: (map['qrPayload'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'walkId': walkId,
      'qrPayload': qrPayload,
    };
  }
}

/// ============================================================
/// QR SCAN STATE
/// ============================================================

class QRScanState {
  final bool scanned;
  final bool connected;

  final String ownerId;
  final String walkerId;
  final String walkerName;
  final String walkId;

  const QRScanState({
    this.scanned = false,
    this.connected = false,
    this.ownerId = '',
    this.walkerId = '',
    this.walkerName = '',
    this.walkId = '',
  });

  factory QRScanState.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};

    return QRScanState(
      scanned: data['scanned'] == true,
      connected: data['connected'] == true,
      ownerId: (data['ownerId'] ?? '').toString(),
      walkerId: (data['walkerId'] ?? '').toString(),
      walkerName: (data['walkerName'] ?? '').toString(),
      walkId: (data['walkId'] ?? '').toString(),
    );
  }

  @override
  String toString() {
    return 'QRScanState('
        'scanned: $scanned, '
        'connected: $connected, '
        'ownerId: $ownerId, '
        'walkerId: $walkerId, '
        'walkerName: $walkerName, '
        'walkId: $walkId'
        ')';
  }
}

/// ============================================================
/// QR SERVICE
/// ============================================================
///
/// Owner:
///     createOwnerQR()
///     watchScan(ownerId)
///
/// Walker:
///     scan QR payload
///     markWalkerConnected()
///
/// Firestore:
///     qr_connections/{ownerId}
/// ============================================================

class QRService {
  QRService._();

  static final QRService instance = QRService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _connections =>
          _firestore.collection('qr_connections');

  /// ==========================================================
  /// CREATE OWNER QR
  /// ==========================================================

  Future<QRData> createOwnerQR() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Owner login required.',
      );
    }

    final String ownerId = user.uid;

    // ----------------------------------------------------------
    // OWNER NAME
    // ----------------------------------------------------------

    String ownerName = 'Owner';

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> ownerDoc =
          await _firestore
              .collection('owners')
              .doc(ownerId)
              .get();

      final Map<String, dynamic>? ownerData =
          ownerDoc.data();

      if (ownerData != null) {
        ownerName =
            (ownerData['name'] ??
                    ownerData['Name'] ??
                    ownerData['ownerName'] ??
                    ownerData['Full Name'] ??
                    'Owner')
                .toString();
      }
    } catch (_) {
      // Keep fallback name.
    }

    // ----------------------------------------------------------
    // WALK ID
    // ----------------------------------------------------------

    final String walkId =
        'walk_${DateTime.now().millisecondsSinceEpoch}';

    // ----------------------------------------------------------
    // QR PAYLOAD
    // ----------------------------------------------------------

    final Map<String, dynamic> payload = {
      'type': 'dojo_owner_qr',
      'version': 1,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'walkId': walkId,
    };

    final String qrPayload =
        jsonEncode(payload);

    // ----------------------------------------------------------
    // CREATE / RESET CONNECTION
    // ----------------------------------------------------------

    await _connections.doc(ownerId).set(
      {
        'type': 'dojo_owner_qr',
        'version': 1,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'walkId': walkId,

        'scanned': false,
        'connected': false,

        'walkerId': null,
        'walkerName': null,

        'createdAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: false),
    );

    return QRData(
      ownerId: ownerId,
      ownerName: ownerName,
      walkId: walkId,
      qrPayload: qrPayload,
    );
  }

  /// ==========================================================
  /// WATCH WALKER SCAN
  /// ==========================================================

  Stream<QRScanState> watchScan(
    String ownerId,
  ) {
    if (ownerId.trim().isEmpty) {
      return Stream<QRScanState>.error(
        Exception('Invalid owner ID.'),
      );
    }

    return _connections
        .doc(ownerId)
        .snapshots()
        .map(
      (DocumentSnapshot<
              Map<String, dynamic>> snapshot) {
        if (!snapshot.exists) {
          return const QRScanState();
        }

        return QRScanState
            .fromFirestore(snapshot);
      },
    );
  }

  /// ==========================================================
  /// WALKER CONNECT
  /// ==========================================================
  ///
  /// Walker app QR scan के बाद इस method को call कर सकता है.
  /// ==========================================================

  Future<void> markWalkerConnected({
    required String ownerId,
    required String walkerId,
    String walkerName = '',
    String? walkId,
  }) async {
    if (ownerId.trim().isEmpty) {
      throw Exception(
        'Owner ID is required.',
      );
    }

    if (walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID is required.',
      );
    }

    await _connections.doc(ownerId).set(
      {
        'ownerId': ownerId,
        'walkerId': walkerId,
        'walkerName': walkerName,

        'scanned': true,
        'connected': true,

        if (walkId != null &&
            walkId.trim().isNotEmpty)
          'walkId': walkId,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// ==========================================================
  /// MARK QR SCANNED
  /// ==========================================================

  Future<void> markScanned({
    required String ownerId,
    required String walkerId,
    String walkerName = '',
    String? walkId,
  }) async {
    if (ownerId.trim().isEmpty) {
      throw Exception(
        'Owner ID is required.',
      );
    }

    if (walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID is required.',
      );
    }

    await _connections.doc(ownerId).set(
      {
        'ownerId': ownerId,
        'walkerId': walkerId,
        'walkerName': walkerName,

        'scanned': true,

        if (walkId != null &&
            walkId.trim().isNotEmpty)
          'walkId': walkId,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// ==========================================================
  /// END / CLEAR CONNECTION
  /// ==========================================================

  Future<void> clearConnection(
    String ownerId,
  ) async {
    if (ownerId.trim().isEmpty) {
      return;
    }

    await _connections.doc(ownerId).set(
      {
        'scanned': false,
        'connected': false,
        'walkerId': null,
        'walkerName': null,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// ==========================================================
  /// DELETE CONNECTION
  /// ==========================================================

  Future<void> deleteConnection(
    String ownerId,
  ) async {
    if (ownerId.trim().isEmpty) {
      return;
    }

    await _connections
        .doc(ownerId)
        .delete();
  }

  /// ==========================================================
  /// PARSE QR PAYLOAD
  /// ==========================================================

  static Map<String, dynamic> parsePayload(
    String rawPayload,
  ) {
    final String value =
        rawPayload.trim();

    if (value.isEmpty) {
      throw const FormatException(
        'Empty QR code.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(value);
    } catch (_) {
      throw const FormatException(
        'Invalid Dojo QR code.',
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        'Invalid QR payload.',
      );
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      decoded,
    );

    if (data['type'] !=
        'dojo_owner_qr') {
      throw const FormatException(
        'This QR code is not a Dojo Owner QR.',
      );
    }

    final String ownerId =
        (data['ownerId'] ?? '').toString();

    if (ownerId.isEmpty) {
      throw const FormatException(
        'Owner ID missing from QR.',
      );
    }

    return data;
  }

  /// ==========================================================
  /// QR DATA FROM PAYLOAD
  /// ==========================================================

  static QRData dataFromPayload(
    String rawPayload,
  ) {
    final Map<String, dynamic> data =
        parsePayload(rawPayload);

    return QRData(
      ownerId:
          (data['ownerId'] ?? '').toString(),
      ownerName:
          (data['ownerName'] ?? 'Owner')
              .toString(),
      walkId:
          (data['walkId'] ?? '').toString(),
      qrPayload: rawPayload,
    );
  }
}
