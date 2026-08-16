import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'custom_app_bar.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color background = Color(0xFFEDEFF2);

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
          // =========================================
          // PAGE TITLE
          // =========================================

          Row(
            children: [
              Container(
                height: 21,
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
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

          // =========================================
          // CONTENT AREA
          // =========================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD6DAE0),
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Find a Walker',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Start a walk request and find an available walker nearby.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: slate,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Insta Walk container
                      // ko yahan connect kar sakte ho.
                    },
                    icon: const Icon(
                      Icons.search_rounded,
                    ),
                    label: const Text(
                      'Find a Walker',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
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
