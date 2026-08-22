// File location:
// lib/features/insta_walk/widgets/insta_walk_retry.dart

import 'package:flutter/material.dart';

class InstaWalkRetry extends StatelessWidget {
  final VoidCallback onRetry;

  const InstaWalkRetry({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: .10),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.person_search_rounded,
                color: Color(0xFF8FFFEF),
                size: 22,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'No walker accepted this request.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 21,
            ),
            label: const Text(
              'Search Again',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF65D6C8),
              foregroundColor: const Color(0xFF172733),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
