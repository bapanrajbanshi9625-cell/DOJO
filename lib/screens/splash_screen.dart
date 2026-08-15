import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'main_navigation_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Firebase check immediately start hoga.
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;

    // Firebase session nahi hai
    if (user == null) {
      _goTo(const LoginScreen());
      return;
    }

    try {
      // Firebase Auth session ke baad
      // Owner profile Firestore se fetch hoga.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data();

        // Owner profile complete hai
        if (data != null && data['role'] == 'owner') {
          _goTo(const MainNavigationScreen());
          return;
        }
      }

      // Login hai lekin owner profile nahi hai
      _goTo(const ProfileScreen());
    } on FirebaseException {
      if (!mounted) return;

      // Firebase temporary error:
      // session available hai, isliye app ke andar bhejenge.
      _goTo(const MainNavigationScreen());
    } catch (_) {
      if (!mounted) return;

      _goTo(const MainNavigationScreen());
    }
  }

  void _goTo(Widget screen) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Splash background
          Image.asset(
            'assets/dojo_splash.png',
            fit: BoxFit.cover,
          ),

          // Simple circular loading
          Positioned(
            left: 0,
            right: 0,
            bottom: 65,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Getting things ready...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
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
