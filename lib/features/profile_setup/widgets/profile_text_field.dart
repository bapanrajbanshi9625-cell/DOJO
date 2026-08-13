import 'package:flutter/material.dart';

class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
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

        TextField(
          controller: controller,
          textCapitalization:
              TextCapitalization.words,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: orange,
            ),
            hintText: hint,
            filled: true,
            fillColor:
                const Color(0xFFF7F7F7),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide:
                  BorderSide.none,
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(14),
              borderSide:
                  const BorderSide(
                color: orange,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
