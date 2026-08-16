import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/network/network_monitor.dart';
import 'screens/splash_screen.dart';

class DojoApp extends StatelessWidget {
  final String? startupError;

  const DojoApp({
    super.key,
    this.startupError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo Walk',

      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),

      debugShowCheckedModeBanner: false,

      home: NetworkMonitor(
        child: SplashScreen(
          startupError: startupError,
        ),
      ),
    );
  }
}
