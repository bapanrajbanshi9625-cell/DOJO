import 'package:flutter/material.dart';

class ProfileNumberBox
    extends StatelessWidget {
  static const Color orange =
      Color(0xFFF4511E);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  static const Color textGrey =
      Color(0xFF707070);

  final String title;
  final String number;
  final IconData icon;
  final bool showVerified;

  const ProfileNumberBox({
    super.key,
    required this.title,
    required this.number,
    required this.icon,
    this.showVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(15),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF7F7F7),

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,

            decoration:
                const BoxDecoration(
              color: lightOrange,
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: orange,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style:
                      const TextStyle(
                    color: textGrey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  number,

                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (showVerified)
            const Icon(
              Icons.verified_rounded,
              color: Colors.green,
              size: 23,
            ),
        ],
      ),
    );
  }
}
