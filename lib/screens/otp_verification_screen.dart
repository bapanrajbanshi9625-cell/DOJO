import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  // ============================================================
  // CONTROLLER
  // ============================================================

  final TextEditingController _otpController =
      TextEditingController();

  final FocusNode _otpFocusNode =
      FocusNode();

  // ============================================================
  // STATE
  // ============================================================

  bool _isVerifying = false;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFF4511E);

  static const Color dark =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFF8F9FA);

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    final String otp =
        _otpController.text.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (otp.length != 6) {
      _showMessage(
        'Please enter the complete 6-digit OTP.',
      );

      _otpFocusNode.requestFocus();
      return;
    }

    if (_isVerifying) {
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
            widget.verificationId,
        smsCode: otp,
      );

      // ========================================================
      // 2. FIREBASE AUTH LOGIN
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
          'Firebase user was not found.',
        );
      }

      // ========================================================
      // BACKEND UID
      // ========================================================

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        throw Exception(
          'Firebase UID was not found.',
        );
      }

      // ========================================================
      // VERIFIED PHONE
      // ========================================================

      String phoneNumber =
          user.phoneNumber?.trim() ?? '';

      if (phoneNumber.isEmpty) {
        phoneNumber =
            widget.phoneNumber.trim();

        if (!phoneNumber.startsWith('+')) {
          phoneNumber =
              '+91$phoneNumber';
        }
      }

      // ========================================================
      // 3. GET / CREATE OWNER ID
      // ========================================================
      //
      // Example:
      //
      // OWN26GM0001
      //
      // UID remains backend-only.
      //
      // ========================================================

      final String ownerId =
          await OwnerIdService.instance
              .getOrCreateOwnerId(
        uid: uid,
        phoneNumber: phoneNumber,
      );

      debugPrint(
        'Owner ID: $ownerId',
      );

      // ========================================================
      // 4. LOAD OWNER PROFILE
      // ========================================================

      final DocumentSnapshot<
          Map<String, dynamic>> profileSnapshot =
          await FirebaseFirestore.instance
              .collection('ownerProfiles')
              .doc(ownerId)
              .get();

      // ========================================================
      // 5. PROFILE DATA
      // ========================================================

      final Map<String, dynamic>? data =
          profileSnapshot.data();

      // ========================================================
      // 6. ACTIVE STATUS
      // ========================================================
      //
      // New profile:
      // OwnerIdService creates isActive = true
      //
      // Admin can later set:
      //
      // true  = active
      // false = inactive
      //
      // ========================================================

      final bool isActive =
          data?['isActive'] != false;

      if (!isActive) {
        await FirebaseAuth.instance
            .signOut();

        if (!mounted) return;

        _showInactiveDialog(
          ownerId,
        );

        return;
      }

      // ========================================================
      // 7. PROFILE COMPLETED
      // ========================================================

      final bool profileCompleted =
          data?['profileCompleted'] == true;

      if (!mounted) return;

      // ========================================================
      // 8. PROFILE NOT COMPLETED
      // ========================================================

      if (!profileCompleted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ProfileSetupScreen(),
          ),
          (route) => false,
        );

        return;
      }

      // ========================================================
      // 9. PROFILE COMPLETED → HOME
      // ========================================================

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MainNavigationScreen(),
        ),
        (route) => false,
      );
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        'Owner OTP Auth Error: ${e.code}',
      );

      String message;

      switch (e.code) {
        case 'invalid-verification-code':
          message =
              'Invalid OTP. Please check the code and try again.';
          break;

        case 'session-expired':
          message =
              'This OTP has expired. Please request a new OTP.';
          break;

        case 'invalid-verification-id':
          message =
              'Verification session expired. Please request a new OTP.';
          break;

        case 'credential-already-in-use':
          message =
              'This mobile number is already linked to another account.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        default:
          message =
              'OTP verification failed. Please try again.';
      }

      if (!mounted) return;

      _showMessage(message);
    }

    // ==========================================================
    // FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Owner Firestore Error: ${e.code}',
      );

      if (!mounted) return;

      _showMessage(
        e.message ??
            'Unable to load your Owner profile. Please try again.',
      );
    }

    // ==========================================================
    // GENERAL ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        'Owner OTP Error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
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
  // INACTIVE OWNER DIALOG
  // ============================================================

  void _showInactiveDialog(
    String ownerId,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.block_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Account Inactive',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your Owner ID $ownerId is currently inactive.\n\n'
            'Please contact support to activate your account.',
            style: const TextStyle(
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: orange,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
            background,
        elevation: 0,
        foregroundColor: dark,
        automaticallyImplyLeading:
            true,
        toolbarHeight: 55,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context)
                .unfocus();
          },
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,
            padding:
                const EdgeInsets.fromLTRB(
              22,
              10,
              22,
              30,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // TOP ICON
                // ==================================================

                Center(
                  child: Container(
                    height: 78,
                    width: 78,
                    decoration:
                        BoxDecoration(
                      color: orange,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: orange
                              .withOpacity(
                            0.22,
                          ),
                          blurRadius: 18,
                          offset:
                              const Offset(
                            0,
                            8,
                          ),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 26,
                ),

                // ==================================================
                // TITLE
                // ==================================================

                const Center(
                  child: Text(
                    'Verify your number',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: dark,
                      fontSize: 27,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 9,
                ),

                // ==================================================
                // SUBTITLE
                // ==================================================

                Center(
                  child: Text(
                    'Enter the 6-digit OTP sent to',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey
                          .shade600,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                // ==================================================
                // PHONE
                // ==================================================

                Center(
                  child: Text(
                    _displayPhoneNumber(),
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: dark,
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),

                // ==================================================
                // OTP CARD
                // ==================================================

                Container(
                  width:
                      double.infinity,
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    20,
                    18,
                    20,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(
                          0.05,
                        ),
                        blurRadius: 18,
                        offset:
                            const Offset(
                          0,
                          6,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'One-Time Password',
                        style: TextStyle(
                          color: dark,
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // OTP FIELD
                      // ==================================================

                      TextField(
                        controller:
                            _otpController,
                        focusNode:
                            _otpFocusNode,
                        autofocus: true,
                        enabled:
                            !_isVerifying,
                        keyboardType:
                            TextInputType.number,
                        textInputAction:
                            TextInputAction.done,
                        maxLength: 6,
                        textAlign:
                            TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                        ],
                        onSubmitted: (_) {
                          if (!_isVerifying) {
                            _verifyOtp();
                          }
                        },
                        style:
                            const TextStyle(
                          color: dark,
                          fontSize: 25,
                          fontWeight:
                              FontWeight.w800,
                          letterSpacing: 10,
                        ),
                        decoration:
                            InputDecoration(
                          hintText:
                              '------',
                          hintStyle:
                              TextStyle(
                            color: Colors.grey
                                .shade300,
                            fontSize: 24,
                            letterSpacing: 9,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor:
                              const Color(
                            0xFFF8F8F8,
                          ),
                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 17,
                          ),
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color: Colors.grey
                                  .shade200,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color: Colors.grey
                                  .shade200,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            borderSide:
                                const BorderSide(
                              color: orange,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // VERIFY BUTTON
                      // ==================================================

                      SizedBox(
                        width:
                            double.infinity,
                        height: 54,
                        child:
                            ElevatedButton(
                          onPressed:
                              _isVerifying
                                  ? null
                                  : _verifyOtp,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                orange,
                            disabledBackgroundColor:
                                orange.withOpacity(
                              0.55,
                            ),
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          child:
                              _isVerifying
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth:
                                            2.5,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Verify & Continue',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight.w800,
                                      ),
                                    ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // SECURITY INFO
                // ==================================================

                Center(
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons
                            .lock_outline_rounded,
                        size: 15,
                        color: Colors.grey
                            .shade600,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Text(
                        'Secure phone verification',
                        style: TextStyle(
                          color: Colors.grey
                              .shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Center(
                  child: Text(
                    'Your Firebase UID is kept in the backend.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey
                          .shade500,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPLAY PHONE
  // ============================================================

  String _displayPhoneNumber() {
    final String raw =
        widget.phoneNumber.trim();

    final String clean =
        raw.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length == 10) {
      return '+91 '
          '${clean.substring(0, 5)} '
          '${clean.substring(5)}';
    }

    if (clean.length >= 10) {
      final String last10 =
          clean.substring(
        clean.length - 10,
      );

      return '+91 '
          '${last10.substring(0, 5)} '
          '${last10.substring(5)}';
    }

    return raw.isEmpty
        ? 'Mobile number'
        : raw;
  }
}
