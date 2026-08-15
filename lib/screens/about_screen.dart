import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'About Dojo Walk',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pets,
                color: AppColors.primary,
                size: 60,
              ),

              SizedBox(height: 15),

              Text(
                'Dojo Walk',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Dog walking made simple.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.slate,
                ),
              ),

              SizedBox(height: 18),

              Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: AppColors.slate,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
