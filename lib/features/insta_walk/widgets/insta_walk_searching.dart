import 'package:flutter/material.dart';

class InstaWalkSearching extends StatelessWidget {
  final String timerText;
  final Widget map;

  const InstaWalkSearching({
    super.key,
    required this.timerText,
    required this.map,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF65D6C8)
                    .withValues(alpha: .18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Color(0xFF8FFFEF),
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Finding an available walker',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(alpha: .12),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Text(
                timerText,
                style: const TextStyle(
                  color: Color(0xFF8FFFEF),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        map,

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: .08),
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: .10),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF8FFFEF),
                size: 17,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your location is used only as a search snapshot.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
