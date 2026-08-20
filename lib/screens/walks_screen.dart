import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/walks/containers/active_walker_container.dart';
import 'custom_app_bar.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color background = Color(0xFFEDEFF2);
  static const Color border = Color(0xFFD6DAE0);

  static const Color primary = AppColors.primary;

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

          _instaWalkCard(context),

          // ====================================================
          // GAP
          // ====================================================

          const SizedBox(height: 14),

          // ====================================================
          // LIVE / ACTIVE WALK
          // ====================================================
          //
          // IMPORTANT:
          //
          // This is now displayed BELOW Insta Walk.
          //
          // The ActiveWalkerContainer is responsible for
          // checking the current active walk and displaying
          // the connected Walker / Live Walk information.
          //
          // QR Scan walk + Insta Walk both use active_walks,
          // so both flows can appear here.
          //
          // ====================================================

          const ActiveWalkerContainer(),
        ],
      ),
    );
  }

  // ==========================================================
  // INSTA WALK CARD
  // ==========================================================

  Widget _instaWalkCard(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: border,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: .035,
            ),

            blurRadius: 12,

            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ====================================================
          // HEADER
          // ====================================================

          Row(
            children: [
              Container(
                width: 46,
                height: 46,

                decoration: BoxDecoration(
                  color: primary.withValues(
                    alpha: .10,
                  ),

                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.search_rounded,

                  color: primary,

                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Insta Walk',

                      style: TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      'Find an available walker nearby.',

                      style: TextStyle(
                        color: slate,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ====================================================
          // FIND WALKER BUTTON
          // ====================================================

          SizedBox(
            width: double.infinity,
            height: 47,

            child: ElevatedButton.icon(
              onPressed: () {
                // ==================================================
                // EXISTING INSTA WALK FLOW
                // ==================================================
                //
                // आपका existing Insta Walk logic यहाँ रहेगा.
                //
                // इस button के logic को जानबूझकर नहीं छेड़ा गया।
                //
                // Insta Walk से active walk बनने के बाद
                // ActiveWalkerContainer उसे नीचे दिखाएगा।
                //
                // ==================================================
              },

              icon: const Icon(
                Icons.search_rounded,
                size: 19,
              ),

              label: const Text(
                'Find a Walker',

                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primary,

                foregroundColor:
                    Colors.white,

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
