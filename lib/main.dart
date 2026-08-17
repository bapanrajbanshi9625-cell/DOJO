import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stackTrace) {
    debugPrint(
      'Firebase initialization error: $e',
    );

    debugPrintStack(
      stackTrace: stackTrace,
    );
  }

  runApp(
    const DojoApp(),
  );
}
