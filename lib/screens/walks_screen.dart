// File location: lib/screens/walks_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../features/walks/containers/active_walker_container.dart';

import 'custom_app_bar.dart';
import 'generate_qr_screen.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color background = Color(0xFFEDEFF2);

  static const Color primary = AppColors.primary;

  // ==========================================================
  // COMPACT QR BUTTON
  // ==========================================================

  Widget _qrButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 0.78,
          alignment: Alignment.centerRight,
          child: GenerateQRButton(),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const CustomAppBar(),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          15,
          18,
          15,
          110,
        ),
        children: [
          // ====================================================
          // PAGE TITLE
          // ====================================================

          Row(
            children: [
              Container(
                height: 21,
                width: 4,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius:
                      BorderRadius.circular(5),
                ),
              ),

              const SizedBox(width: 9),

              const Text(
                'Walks',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Find and manage your dog walks.',
            style: TextStyle(
              color: slate,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // INSTA WALK
          // ====================================================

          const InstaWalkContainer(),

          const SizedBox(height: 4),

          // ====================================================
          // QR BUTTON
          // ====================================================
          //
          // Compact QR button stays OUTSIDE the Insta Walk
          // container so the Insta Walk UI remains untouched.
          // ====================================================

          _qrButton(),

          const SizedBox(height: 2),

          // ====================================================
          // ACTIVE WALKER
          // ====================================================

          ActiveWalkerContainer(),
        ],
      ),
    );
  }
}
