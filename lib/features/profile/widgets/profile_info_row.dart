import 'package:flutter/material.dart';

class ProfileInfoRow
    extends StatelessWidget {
  static const Color orange =
      Color(0xFFF4511E);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  static const Color textGrey =
      Color(0xFF707070);

  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,

        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                const BoxDecoration(
              color: lightOrange,
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: orange,
              size: 23,
            ),
          ),

          const SizedBox(width: 13),

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
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value.isEmpty
                      ? '-'
                      : value,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
