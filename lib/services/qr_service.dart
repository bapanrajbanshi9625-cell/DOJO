import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class QRService {
  QRService._();

  static final QRService instance = QRService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ==========================================================
  // GET REAL OWNER ID
  // ==========================================================

  Future<String?> getOwnerId() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('ownerProfiles')
            .doc(user.uid)
            .get();

    final Map<String, dynamic>? data =
        snapshot.data();

    final String ownerId =
        data?['ownerId']
                ?.toString()
                .trim() ??
            '';

    if (ownerId.isEmpty) {
      return null;
    }

    return ownerId;
  }

  // ==========================================================
  // GET OWNER PROFILE
  // ==========================================================

  Future<Map<String, dynamic>?> getOwnerProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore
            .collection('ownerProfiles')
            .doc(user.uid)
            .get();

    return snapshot.data();
  }

  // ==========================================================
  // CURRENT LOCATION
  // ==========================================================

  Future<Position?> getCurrentLocation() async {
    try {
      final bool enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint(
        'QR location error: $e',
      );

      return null;
    }
  }

  // ==========================================================
  // CREATE QR
  // ==========================================================

  Future<QRData?> createOwnerQR() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Owner is not logged in.',
      );
    }

    // --------------------------------------------------------
    // REAL OWNER ID
    // --------------------------------------------------------

    final String? ownerId =
        await getOwnerId();

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      throw Exception(
        'Owner ID not found.',
      );
    }

    // --------------------------------------------------------
    // PROFILE
    // --------------------------------------------------------

    final Map<String, dynamic>? profile =
        await getOwnerProfile();

    final String ownerName =
        profile?['Full Name']
                ?.toString()
                .trim()
                .isNotEmpty ==
            true
        ? profile!['Full Name']
            .toString()
            .trim()
        : user.displayName
                ?.trim()
                .isNotEmpty ==
            true
            ? user.displayName!.trim()
            : 'Owner';

    // --------------------------------------------------------
    // PHONE
    // --------------------------------------------------------

    final String ownerPhone =
        profile?['Mobile number']
                ?.toString()
                .trim() ??
            user.phoneNumber
                ?.trim() ??
            '';

    // --------------------------------------------------------
    // WALK ID
    // --------------------------------------------------------

    final String walkId =
        'WALK_${DateTime.now().millisecondsSinceEpoch}';

    // --------------------------------------------------------
    // LOCATION
    // --------------------------------------------------------

    final Position? position =
        await getCurrentLocation();

    final Map<String, dynamic>
        location =
        <String, dynamic>{};

    if (position != null) {
      location['latitude'] =
          position.latitude;

      location['longitude'] =
          position.longitude;

      location['accuracy'] =
          position.accuracy;
    }

    // --------------------------------------------------------
    // QR PAYLOAD
    // --------------------------------------------------------
    //
    // IMPORTANT:
    // QR में Firebase Auth UID नहीं जाएगा.
    // QR में REAL OWNER ID जाएगा.
    //
    // --------------------------------------------------------

    final Map<String, dynamic> payload =
        <String, dynamic>{
      'type': 'owner',

      'ownerId': ownerId,

      'ownerName': ownerName,

      'walkId': walkId,

      if (position != null)
        'ownerLocation': location,

      'ownerLocationType': 'saved',

      'walkStarted': false,

      'walkEnded': false,

      'walkerTracking': false,
    };

    final String qrPayload =
        jsonEncode(payload);

    // --------------------------------------------------------
    // FIRESTORE
    // --------------------------------------------------------

    await _firestore
        .collection('qr_codes')
        .doc(ownerId)
        .set(
      <String, dynamic>{
        ...payload,

        // Compatibility
        'ownerId': ownerId,

        'uid': user.uid,

        'userId': user.uid,

        'name': ownerName,

        'phoneNumber': ownerPhone,

        'qrData': qrPayload,

        // Scan state
        'scanned': false,

        'scannedBy': null,

        'scannedAt': null,

        // Connection state
        'connected': false,

        'connectedWalkerId': null,

        'connectedWalkerName': null,

        'trackingStarted': false,

        'trackingEnded': false,

        if (position != null)
          'ownerLocationSavedAt':
              FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return QRData(
      ownerId: ownerId,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      walkId: walkId,
      qrPayload: qrPayload,
    );
  }

  // ==========================================================
  // LISTEN FOR WALKER SCAN
  // ==========================================================

  Stream<QRScanState> watchScan(
    String ownerId,
  ) {
    return _firestore
        .collection('qr_codes')
        .doc(ownerId)
        .snapshots()
        .map(
      (DocumentSnapshot<Map<String, dynamic>>
          snapshot) {
        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        return QRScanState.fromMap(
          data,
        );
      },
    );
  }

  // ==========================================================
  // MARK QR CLOSED
  // ==========================================================

  Future<void> closeQR(
    String ownerId,
  ) async {
    await _firestore
        .collection('qr_codes')
        .doc(ownerId)
        .set(
      <String, dynamic>{
        'scanned': false,
        'connected': false,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}

// ============================================================
// QR DATA
// ============================================================

class QRData {
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String walkId;
  final String qrPayload;

  const QRData({
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.walkId,
    required this.qrPayload,
  });
}

// ============================================================
// QR SCAN STATE
// ============================================================

class QRScanState {
  final bool scanned;
  final bool connected;

  final String? walkerId;
  final String? walkerName;

  const QRScanState({
    required this.scanned,
    required this.connected,
    this.walkerId,
    this.walkerName,
  });

  factory QRScanState.fromMap(
    Map<String, dynamic> data,
  ) {
    return QRScanState(
      scanned:
          data['scanned'] == true,
      connected:
          data['connected'] == true,
      walkerId:
          data['connectedWalkerId']
              ?.toString(),
      walkerName:
          data['connectedWalkerName']
              ?.toString(),
    );
  }
}
