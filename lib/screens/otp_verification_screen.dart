import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/owner_id_service.dart';
import 'main_navigation_screen.dart';
import 'profile_setup.dart';

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

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final TextEditingController _otpController =
      TextEditingController();

  bool _isVerifying = false;

  static const Color dojoOrange =
      Color(0xFFFF5A1F);

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    final String otp =
        _otpController.text.trim();

    // ----------------------------------------------------------
    // OTP VALIDATION
    // ----------------------------------------------------------

    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the 6-digit OTP',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      // ========================================================
      // 1. CREATE PHONE CREDENTIAL
      // ========================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId:
            widget.verificationId.trim(),
        smsCode: otp,
      );

      // ========================================================
      // 2. FIREBASE SIGN IN
      // ========================================================

      final UserCredential userCredential =
          await FirebaseAuth.instance
              .signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      if (user == null) {
        throw Exception(
          'Firebase user not found.',
        );
      }

      final String uid = user.uid;

      debugPrint(
        '========================================',
      );
      debugPrint(
        'FIREBASE LOGIN SUCCESS',
      );
      debugPrint(
        'UID: $uid',
      );
      debugPrint(
        'PHONE: ${user.phoneNumber}',
      );
      debugPrint(
        '========================================',
      );

      // ========================================================
      // 3. CREATE / GET OWNER ID
      // ========================================================

      final String ownerId =
          await OwnerIdService.instance
              .getOrCreateOwnerId(
        uid: uid,
        phoneNumber:
            widget.phoneNumber,
      );

      debugPrint(
        '========================================',
      );
      debugPrint(
        'OWNER ACCOUNT READY',
      );
      debugPrint(
        'OWNER ID: $ownerId',
      );
      debugPrint(
        '========================================',
      );

      // ========================================================
      // 4. CHECK USERS/{UID}
      // ========================================================

      final DocumentSnapshot<
          Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

      bool profileExists =
          userDoc.exists;

      // ========================================================
      // 5. CHECK OLD USER BY PHONE
      // ========================================================

      if (!profileExists) {
        final String fullPhoneNumber =
            '+91${widget.phoneNumber.trim()}';

        final QuerySnapshot<
            Map<String, dynamic>> oldUserQuery =
            await FirebaseFirestore.instance
                .collection('users')
                .where(
                  'phone',
                  isEqualTo:
                      fullPhoneNumber,
                )
                .limit(1)
                .get();

        if (oldUserQuery.docs.isNotEmpty) {
          profileExists = true;
        }
      }

      // ========================================================
      // CHECK MOUNTED
      // ========================================================

      if (!mounted) return;

      // ========================================================
      // 6. EXISTING PROFILE → HOME
      // ========================================================

      if (profileExists) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MainNavigationScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // 7. NEW OWNER → PROFILE SETUP
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ProfileSetupScreen(),
        ),
        (route) => false,
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Error: ${e.code}',
      );
      debugPrint(
        'Message: ${e.message}',
      );

      String message;

      switch (e.code) {
        case 'invalid-verification-code':
          message =
              'Invalid OTP. Please enter the correct OTP.';
          break;

        case 'session-expired':
          message =
              'OTP has expired. Please request a new OTP.';
          break;

        case 'invalid-verification-id':
          message =
              'Verification session is invalid. Please request a new OTP.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        default:
          message =
              'OTP verification failed. Please try again.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }

    // ==========================================================
    // FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Firestore Error: ${e.code}',
      );
      debugPrint(
        'Firestore Message: ${e.message}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firebase Error: ${e.code}\n'
            '${e.message ?? 'Database error.'}',
          ),
        ),
      );
    }

    // ==========================================================
    // GENERAL ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'Owner login error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Owner account setup failed:\n$e',
          ),
        ),
      );
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F7F7),

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        iconTheme:
            const IconThemeData(
          color: Colors.black87,
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ==================================================
              // OTP ICON
              // ==================================================

              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      dojoOrange,
                  child: Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // TITLE
              // ==================================================

              const Center(
                child: Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black87,
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // PHONE
              // ==================================================

              Center(
                child: Text(
                  'Enter the 6-digit code sent to '
                  '+91 ${widget.phoneNumber}',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              // ==================================================
              // LABEL
              // ==================================================

              const Text(
                'Enter OTP',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Colors.black87,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // OTP FIELD
              // ==================================================

              TextField(
                controller:
                    _otpController,
                keyboardType:
                    TextInputType.number,
                maxLength: 6,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration:
                    InputDecoration(
                  hintText: '------',
                  counterText: '',
                  filled: true,
                  fillColor:
                      Colors.white,

                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(12),
                    borderSide:
                        BorderSide(
                      color: Colors
                          .grey.shade300,
                    ),
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(12),
                    borderSide:
                        BorderSide(
                      color: Colors
                          .grey.shade300,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(12),
                    borderSide:
                        const BorderSide(
                      color:
                          dojoOrange,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // VERIFY BUTTON
              // ==================================================

              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        dojoOrange,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(12),
                    ),
                  ),

                  onPressed:
                      _isVerifying
                          ? null
                          : _verifyOtp,

                  child:
                      _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.5,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify & Proceed',
                              style:
                                  TextStyle(
                                fontSize:
                                    16,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    Colors.white,
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
