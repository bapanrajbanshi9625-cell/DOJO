import 'package:flutter/material.dart';

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
  });

  final String title;

  static const Color orange = Color(0xFFF4511E);
  static const Color navy = Color(0xFF263746);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 19,
          width: 4,
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(5),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
