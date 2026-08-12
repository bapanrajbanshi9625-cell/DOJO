import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const GenerateQRButtonScreen(),
    );
  }
}

// ======================================================
// GENERATE QR BUTTON SCREEN
// ======================================================

class GenerateQRButtonScreen extends StatelessWidget {
  const GenerateQRButtonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f2f5),
      body: Center(
        child: GenerateQRButton(),
      ),
    );
  }
}

// ======================================================
// GENERATE QR BUTTON
// HOME → FIREBASE → MY QR CODE
// ======================================================

class GenerateQRButton extends StatelessWidget {
  const GenerateQRButton({super.key});

  Future<void> _openOwnerQR(BuildContext context) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    // --------------------------------------------------
    // CHECK LOGIN
    // --------------------------------------------------

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Owner is not logged in.',
          ),
        ),
      );
      return;
    }

    final String uid = user.uid;

    // --------------------------------------------------
    // OWNER INFORMATION
    // --------------------------------------------------

    final String userId = uid;

    final String ownerName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Owner';

    final String phoneNumber =
        user.phoneNumber?.trim().isNotEmpty == true
            ? user.phoneNumber!.trim()
            : '';

    // --------------------------------------------------
    // QR DATA
    // --------------------------------------------------

    final Map<String, dynamic> qrData = {
      'type': 'owner',
      'uid': uid,
      'userId': userId,
      'name': ownerName,
      'phoneNumber': phoneNumber,
    };

    final String qrPayload =
        jsonEncode(qrData);

    // --------------------------------------------------
    // FIREBASE
    // --------------------------------------------------

    try {
      await FirebaseFirestore.instance
          .collection('qr_codes')
          .doc('owner_qr')
          .set(
        {
          'type': 'owner',
          'uid': uid,
          'userId': userId,
          'name': ownerName,
          'phoneNumber': phoneNumber,

          // Actual QR content
          'qrData': qrPayload,

          // Scanner status
          'scanned': false,
          'scannedBy': null,
          'scannedAt': null,

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      // ------------------------------------------------
      // OPEN MY QR CODE
      // ------------------------------------------------

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (context) {
          return const MyQRCodeSheet();
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'QR Firebase save failed: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor:
          const Color(0xFFF4511E),
      foregroundColor: Colors.white,
      elevation: 8,

      // ================================================
      // DIRECTLY OPEN OWNER MY QR
      // NO QR CODE STUDIO
      // ================================================

      onPressed: () {
        _openOwnerQR(context);
      },

      icon: const Icon(
        Icons.qr_code_2,
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
// MY QR CODE BOTTOM SHEET
// ======================================================

class MyQRCodeSheet extends StatelessWidget {
  const MyQRCodeSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('qr_codes')
          .doc('owner_qr')
          .snapshots(),

      builder: (
        context,
        snapshot,
      ) {
        // ------------------------------------------------
        // LOADING
        // ------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return _loadingSheet();
        }

        // ------------------------------------------------
        // FIREBASE ERROR
        // ------------------------------------------------

        if (snapshot.hasError) {
          return _errorSheet(
            'Firebase connection failed.',
          );
        }

        // ------------------------------------------------
        // NO DOCUMENT
        // ------------------------------------------------

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return _errorSheet(
            'Owner QR not found.',
          );
        }

        final Map<String, dynamic> data =
            snapshot.data!.data() ??
                <String, dynamic>{};

        final String qrData =
            data['qrData']?.toString() ?? '';

        final String ownerName =
            data['name']?.toString() ??
                'Owner';

        final String phoneNumber =
            data['phoneNumber']?.toString() ??
                '';

        final bool scanned =
            data['scanned'] == true;

        // ------------------------------------------------
        // WALKER SCANNED OWNER QR
        //
        // Firebase changes scanned → true
        // Bottom sheet automatically closes.
        // ------------------------------------------------

        if (scanned) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });

          return const SizedBox.shrink();
        }

        // ------------------------------------------------
        // MY QR CODE
        // ------------------------------------------------

        return Container(
          width: double.infinity,

          padding:
              const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            32,
          ),

          decoration:
              const BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(
                  0,
                  -5,
                ),
              ),
            ],
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [

              // ==========================================
              // HEADER
              // ==========================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                children: [

                  const SizedBox(
                    width: 40,
                  ),

                  const Text(
                    'My QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xff1f2937),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    icon: const Icon(
                      Icons.close,
                      size: 22,
                      color:
                          Color(0xff4b5563),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              // ==========================================
              // OWNER NAME
              // ==========================================

              Text(
                ownerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xff111827),
                ),
              ),

              if (phoneNumber
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 4,
                ),

                Text(
                  phoneNumber,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xff6b7280),
                  ),
                ),
              ],

              const SizedBox(
                height: 20,
              ),

              // ==========================================
              // REAL QR CODE
              // ==========================================

              Container(
                width: 190,
                height: 190,

                padding:
                    const EdgeInsets.all(
                  12,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),

                  border: Border.all(
                    color:
                        const Color(
                      0xffe5e7eb,
                    ),
                  ),
                ),

                child: qrData.isEmpty
                    ? const Center(
                        child: Text(
                          'QR unavailable',
                          style: TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                      )
                    : QrImageView(
                        data: qrData,
                        version:
                            QrVersions.auto,
                        size: 166,
                        backgroundColor:
                            Colors.white,
                        errorCorrectionLevel:
                            QrErrorCorrectLevel.M,
                      ),
              ),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'Scan this QR code to connect with the Owner.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color:
                      Color(0xff6b7280),
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==========================================
              // WAITING STATUS
              // ==========================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                children: const [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child:
                        DecoratedBox(
                      decoration:
                          BoxDecoration(
                        color:
                            Color(
                          0xff22c55e,
                        ),
                        shape:
                            BoxShape
                                .circle,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 8,
                  ),

                  Text(
                    'Waiting for Walker to scan...',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Color(0xff6b7280),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),
            ],
          ),
        );
      },
    );
  }

  // ====================================================
  // LOADING SHEET
  // ====================================================

  Widget _loadingSheet() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(32),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: const Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading My QR Code...',
          ),
        ],
      ),
    );
  }

  // ====================================================
  // ERROR SHEET
  // ====================================================

  Widget _errorSheet(
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(32),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 50,
            color: Colors.redAccent,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            message,
            textAlign:
                TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color:
                  Color(0xff4b5563),
            ),
          ),

          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }
}
