import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_navigation_screen.dart';
import 'login_screen.dart';
import 'profile_setup.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _checkLoginAndNavigate();
  }

  // ============================================================
  // CHECK LOGIN + PROFILE
  // ============================================================

  Future<void> _checkLoginAndNavigate() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    // ------------------------------------------------------------
    // NO AUTH SESSION
    // ------------------------------------------------------------

    if (user == null) {
      _goTo(
        const LoginScreen(),
      );
      return;
    }

    try {
      // ==========================================================
      // FIREBASE UID
      // ==========================================================

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        _goTo(
          const LoginScreen(),
        );
        return;
      }

      // ==========================================================
      // 1. GET PHONE ACCOUNT
      // ==========================================================

      final DocumentSnapshot<
          Map<String, dynamic>> accountSnapshot =
          await FirebaseFirestore.instance
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      // ----------------------------------------------------------
      // PHONE ACCOUNT NOT FOUND
      // ----------------------------------------------------------

      if (!accountSnapshot.exists) {
        if (!mounted) return;

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic>? accountData =
          accountSnapshot.data();

      // ==========================================================
      // 2. GET OWNER ID
      // ==========================================================

      final dynamic ownerIdValue =
          accountData?['ownerId'];

      if (ownerIdValue is! String ||
          ownerIdValue.trim().isEmpty) {
        if (!mounted) return;

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final String ownerId =
          ownerIdValue.trim();

      // ==========================================================
      // 3. GET OWNER PROFILE
      // ==========================================================

      final DocumentSnapshot<
          Map<String, dynamic>> ownerSnapshot =
          await FirebaseFirestore.instance
              .collection('ownerProfiles')
              .doc(ownerId)
              .get();

      // ----------------------------------------------------------
      // OWNER PROFILE DOES NOT EXIST
      // ----------------------------------------------------------

      if (!ownerSnapshot.exists) {
        if (!mounted) return;

        _goTo(
          const ProfileSetupScreen(),
        );

        return;
      }

      final Map<String, dynamic>? ownerData =
          ownerSnapshot.data();

      // ==========================================================
      // 4. CHECK PROFILE COMPLETED
      // ==========================================================

      final bool profileCompleted =
          ownerData?['profileCompleted'] == true;

      // ==========================================================
      // PROFILE COMPLETE
      // ==========================================================

      if (profileCompleted) {
        if (!mounted) return;

        _goTo(
          const MainNavigationScreen(),
        );

        return;
      }

      // ==========================================================
      // PROFILE NOT COMPLETE
      // ==========================================================

      if (!mounted) return;

      _goTo(
        const ProfileSetupScreen(),
      );
    }

    // ============================================================
    // FIREBASE ERROR
    // ============================================================

    on FirebaseException catch (e) {
      debugPrint(
        'Splash Firebase error: ${e.code}',
      );

      if (!mounted) return;

      // ----------------------------------------------------------
      // Firebase error होने पर authenticated user को
      // blindly MainNavigation पर नहीं भेजेंगे.
      // ----------------------------------------------------------

      _goTo(
        const ProfileSetupScreen(),
      );
    }

    // ============================================================
    // UNKNOWN ERROR
    // ============================================================

    catch (e) {
      debugPrint(
        'Splash error: $e',
      );

      if (!mounted) return;

      _goTo(
        const ProfileSetupScreen(),
      );
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goTo(
    Widget screen,
  ) {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ======================================================
          // SPLASH IMAGE
          // ======================================================

          Image.asset(
            'assets/dojo_splash.png',
            fit: BoxFit.cover,
          ),

          // ======================================================
          // LOADING
          // ======================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 65,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Text(
                  'Getting things ready...',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                const SizedBox(
                  width: 30,
                  height: 30,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
