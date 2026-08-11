import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/constants/app_colors.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  String? _sessionId;
  bool _isGenerating = false;

  Future<void> _generateQr() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner session not found. Please login again.'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final uid = user.uid;

      // Firestore automatically creates a unique document ID.
      final sessionRef =
          FirebaseFirestore.instance.collection('walk_sessions').doc();

      final sessionId = sessionRef.id;

      await sessionRef.set({
        'sessionId': sessionId,
        'ownerUid': uid,
        'walkerUid': null,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'startedAt': null,
        'completedAt': null,
      });

      if (!mounted) return;

      setState(() {
        _sessionId = sessionId;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Walk QR generated successfully'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Failed to generate QR code.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Generate Walk QR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 30),

              const Text(
                'Start a Walk',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Generate a QR code for the walker to scan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 35),

              Container(
                width: 270,
                height: 270,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: _sessionId == null
                    ? const Center(
                        child: Icon(
                          Icons.qr_code_2,
                          size: 150,
                          color: Colors.grey,
                        ),
                      )
                    : QrImageView(
                        data: _sessionId!,
                        version: QrVersions.auto,
                        size: 230,
                        backgroundColor: Colors.white,
                      ),
              ),

              const SizedBox(height: 25),

              if (_sessionId != null) ...[
                const Text(
                  'Show this QR code to the Walker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Session: $_sessionId',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 25),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateQr,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.primary.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: _isGenerating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _sessionId == null
                              ? 'Generate QR Code'
                              : 'Generate New QR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'The walker will scan this code to start the walk.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
