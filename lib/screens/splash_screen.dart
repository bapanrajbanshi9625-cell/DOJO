import 'dart:async';

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
  double progress = 0.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _checkLoginAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;

    // User logged out / no Firebase session
    if (user == null) {
      _goTo(const LoginScreen());
      return;
    }

    try {
      // Firebase UID वाला Owner profile check
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data();

        // Owner profile exists
        if (data != null && data['role'] == 'owner') {
          _goTo(const MainNavigationScreen());
          return;
        }
      }

      // Firebase login है लेकिन Owner profile अभी नहीं है
      _goTo(const ProfileScreen());
    } on FirebaseException {
      if (!mounted) return;

      // Firebase/Firestore temporary error होने पर
      // login session मौजूद है, इसलिए LoginScreen पर
      // वापस नहीं भेजेंगे।
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

  void _startLoading() {
    _timer = Timer.periodic(
      const Duration(milliseconds: 80),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          progress += 0.01;

          if (progress >= 1.0) {
            progress = 1.0;
            timer.cancel();

            Future.delayed(
              const Duration(milliseconds: 300),
              () {
                if (!mounted) return;

                _checkLoginAndNavigate();
              },
            );
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/dojo_splash.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            left: 60,
            right: 60,
            bottom: 55,
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

                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
