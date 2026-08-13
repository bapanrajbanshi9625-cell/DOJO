import 'package:flutter/material.dart';

class ProfileSelectionField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final VoidCallback onTap;

  const ProfileSelectionField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  static const Color orange =
      Color(0xFFF4511E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF7F7F7),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: value == null
                    ? Colors.transparent
                    : orange.withOpacity(0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: orange,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value == null
                          ? const Color(
                              0xFF707070)
                          : Colors.black,
                      fontSize: 15.5,
                      fontWeight:
                          value == null
                              ? FontWeight.w400
                              : FontWeight.w600,
                    ),
                  ),
                ),

                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color:
                      Color(0xFF707070),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
