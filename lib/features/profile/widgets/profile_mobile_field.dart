import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileMobileField
    extends StatelessWidget {
  static const Color orange =
      Color(0xFFF4511E);

  static const Color textGrey =
      Color(0xFF707070);

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const ProfileMobileField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller:
              controller,

          keyboardType:
              TextInputType.phone,

          maxLength: 10,

          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,

            LengthLimitingTextInputFormatter(
              10,
            ),
          ],

          decoration:
              InputDecoration(
            prefixIcon: Icon(
              icon,
              color: orange,
            ),

            hintText: hint,

            counterText: '',

            filled: true,

            fillColor:
                const Color(0xFFF7F7F7),

            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              borderSide:
                  BorderSide.none,
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
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
