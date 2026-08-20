import 'package:flutter/material.dart';

class HomeWelcomeCard extends StatelessWidget {
  const HomeWelcomeCard({super.key});

  static const Color orange = Color(0xFFF4511E);
  static const String dogAsset = 'assets/dog_welcome.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 88,
      padding: const EdgeInsets.only(
        left: 15,
        right: 8,
        top: 10,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF34495E),
            Color(0xFF263746),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // =================================================
          // DOJO PAW
          // =================================================

          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: orange.withOpacity(0.16),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: orange.withOpacity(0.40),
              ),
            ),
            child: const Icon(
              Icons.pets,
              color: orange,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // =================================================
          // WELCOME OFFER MESSAGE
          // =================================================

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Dojo! 🐾',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Enjoy 30% OFF on your first week! 🎉',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // =================================================
          // DOG
          //
          // Transparent PNG.
          // Keep the dog inside THIS file as requested.
          // =================================================

          SizedBox(
            width: 82,
            height: 82,
            child: Image.asset(
              dogAsset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
