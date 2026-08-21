import 'package:flutter/material.dart';

class InstaWalkMiniBar extends StatelessWidget {
  final String petName;
  final String timerText;
  final bool searching;
  final VoidCallback onTap;

  const InstaWalkMiniBar({
    super.key,
    required this.petName,
    required this.timerText,
    required this.searching,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF243746),
              Color(0xFF31515B),
            ],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: const Color(0xFF65D6C8)
                .withValues(alpha: .25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .14),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF65D6C8)
                    .withValues(alpha: .16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: Color(0xFF8FFFEF),
                size: 19,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    petName.isEmpty
                        ? 'Your Pet'
                        : petName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF65D6C8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        searching
                            ? 'Insta Walk searching'
                            : 'Insta Walk active',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (searching) ...[
              Text(
                timerText,
                style: const TextStyle(
                  color: Color(0xFF8FFFEF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
            ],

            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white70,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}
