import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQRButton extends StatelessWidget {
  const GenerateQRButton({super.key});

  Future<void> _generateQR(BuildContext context) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner is not logged in.'),
        ),
      );
      return;
    }

    final String ownerUid = user.uid.trim();

    if (ownerUid.isEmpty) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner UID is missing.'),
        ),
      );
      return;
    }

    final String ownerName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Owner';

    final String ownerPhone =
        user.phoneNumber?.trim().isNotEmpty == true
            ? user.phoneNumber!.trim()
            : '';

    final String walkId =
        'WALK_${DateTime.now().millisecondsSinceEpoch}';

    // ==================================================
    // REAL QR DATA
    // ==================================================

    final Map<String, dynamic> qrData = {
      'type': 'owner',
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'walkId': walkId,
    };

    final String qrPayload = jsonEncode(qrData);

    // ==================================================
    // SAVE TO FIRESTORE
    // ==================================================

    try {
      await FirebaseFirestore.instance
          .collection('qr_codes')
          .doc(ownerUid)
          .set(
        {
          ...qrData,
          'uid': ownerUid,
          'userId': ownerUid,
          'name': ownerName,
          'phoneNumber': ownerPhone,
          'qrData': qrPayload,
          'scanned': false,
          'scannedBy': null,
          'scannedAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // QR फिर भी दिखेगा।
      // Firebase save fail होने पर भी local QR generate होगा.
      debugPrint('Firebase QR save error: $e');
    }

    if (!context.mounted) return;

    // ==================================================
    // OPEN REAL QR BOTTOM SHEET
    // ==================================================

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) {
        return OwnerQRBottomSheet(
          ownerUid: ownerUid,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
          walkId: walkId,
          qrPayload: qrPayload,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFFF4511E),
      foregroundColor: Colors.white,
      elevation: 8,
      onPressed: () => _generateQR(context),
      icon: const Icon(
        Icons.qr_code_2,
        size: 25,
      ),
      label: const Text(
        'Generate QR Code',
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ======================================================
// OWNER QR BOTTOM SHEET
// ======================================================

class OwnerQRBottomSheet extends StatelessWidget {
  final String ownerUid;
  final String ownerName;
  final String ownerPhone;
  final String walkId;
  final String qrPayload;

  const OwnerQRBottomSheet({
    super.key,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerPhone,
    required this.walkId,
    required this.qrPayload,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          24,
          12,
          24,
          30,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==========================================
            // STICKY HANDLE
            // ==========================================

            Container(
              width: 45,
              height: 5,
              margin: const EdgeInsets.only(
                bottom: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffd1d5db),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            // ==========================================
            // HEADER
            // ==========================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My QR Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff111827),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xff4b5563),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ==========================================
            // OWNER NAME
            // ==========================================

            Text(
              ownerName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (ownerPhone.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                ownerPhone,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xff6b7280),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ==========================================
            // REAL SCANNABLE QR
            // ==========================================

            Container(
              width: 230,
              height: 230,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xffe5e7eb),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                errorCorrectionLevel:
                    QrErrorCorrectLevel.H,
              ),
            ),

            const SizedBox(height: 18),

            // ==========================================
            // SCAN MESSAGE
            // ==========================================

            const Text(
              'Scan this QR code to connect with the Owner.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xff6b7280),
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // WAITING STATUS
            // ==========================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xfff0fdf4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xff22c55e),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Waiting for Walker to scan...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff166534),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // WALK ID
            // ==========================================

            Text(
              'Walk ID: $walkId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xff9ca3af),
              ),
            ),

            const SizedBox(height: 5),

            // ==========================================
            // UID - SMALL / HIDDEN STYLE
            // ==========================================

            Text(
              'Owner UID: ${ownerUid.substring(0, ownerUid.length > 8 ? 8 : ownerUid.length)}...',
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xffd1d5db),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
