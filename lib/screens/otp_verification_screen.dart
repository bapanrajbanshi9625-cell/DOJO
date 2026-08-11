import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_navigation_screen.dart';
import 'profile_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;

  // Dojo App Icon Orange
  static const Color dojoOrange = Color(0xFFFF5A1F);

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit OTP'),
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // --------------------------------------------------
      // 1. Create Firebase phone credential
      // --------------------------------------------------

      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      // --------------------------------------------------
      // 2. Sign in with Firebase
      // --------------------------------------------------

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Firebase user not found');
      }

      final uid = user.uid;

      // --------------------------------------------------
      // 3. Check users/{UID}
      // --------------------------------------------------

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      bool profileExists = userDoc.exists;

      // --------------------------------------------------
      // 4. Also check old users collection by phone
      //
      // This helps existing users whose old document ID
      // was not Firebase UID.
      // --------------------------------------------------

      if (!profileExists) {
        final fullPhoneNumber = '+91${widget.phoneNumber}';

        final oldUserQuery = await FirebaseFirestore.instance
            .collection('users')
            .where(
              'phone',
              isEqualTo: fullPhoneNumber,
            )
            .limit(1)
            .get();

        if (oldUserQuery.docs.isNotEmpty) {
          profileExists = true;
        }
      }

      if (!mounted) return;

      // --------------------------------------------------
      // 5. Existing user -> Home
      // --------------------------------------------------

      if (profileExists) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // --------------------------------------------------
      // 6. New user -> Profile
      // --------------------------------------------------

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Invalid OTP. Please enter the correct OTP.';
          break;

        case 'session-expired':
          message = 'OTP has expired. Please request a new OTP.';
          break;

        case 'invalid-verification-id':
          message =
              'Verification session is invalid. Please request a new OTP.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        default:
          message = 'OTP verification failed. Please try again.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Database error. Please try again.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: dojoOrange,
                  child: Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Enter the 6-digit code sent to +91 ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),

                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: dojoOrange,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dojoOrange,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onPressed: _isVerifying ? null : _verifyOtp,

                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify & Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
