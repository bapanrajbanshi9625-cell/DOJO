import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/network/network_monitor.dart';
import 'screens/no_network_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseFailed = false;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrintStack(stackTrace: stackTrace);

    final text = e.toString().toLowerCase();

    firebaseFailed =
        text.contains('network') ||
        text.contains('timeout') ||
        text.contains('socket') ||
        text.contains('connection') ||
        text.contains('unavailable');
  }

  runApp(
    firebaseFailed
        ? const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: NoNetworkScreen(),
          )
        : const DojoApp(),
  );
}
