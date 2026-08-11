import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'screens/splash_screen.dart';

class DojoApp extends StatelessWidget {
  const DojoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo App',

      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),

      // SplashScreen Firebase login session check करेगा.
      home: const SplashScreen(),

      debugShowCheckedModeBanner: false,
    );
  }
}
