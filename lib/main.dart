import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ==========================================================
    // FIREBASE INITIALIZATION
    // ==========================================================

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    debugPrint('Firebase initialized successfully.');

    // ==========================================================
    // START APP
    // ==========================================================

    runApp(
      const DojoApp(),
    );
  } catch (e, stackTrace) {
    // ==========================================================
    // FIREBASE INITIALIZATION FAILED
    // ==========================================================

    debugPrint(
      'Firebase initialization error: $e',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );

    // Do NOT start the normal app when Firebase failed.
    runApp(
      FirebaseStartupErrorApp(
        error: e.toString(),
      ),
    );
  }
}

// ============================================================
// FIREBASE STARTUP ERROR APP
// ============================================================

class FirebaseStartupErrorApp extends StatelessWidget {
  final String error;

  const FirebaseStartupErrorApp({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dojo Walk',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4B16),
        ),
      ),

      home: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 70,
                    color: Color(0xFFFF4B16),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Unable to start Dojo Walk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Firebase could not be initialized.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
