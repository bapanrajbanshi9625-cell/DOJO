import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileOtpField
    extends StatelessWidget {
  static const Color orange =
      Color(0xFFF4511E);

  final TextEditingController controller;

  const ProfileOtpField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:
          controller,

      keyboardType:
          TextInputType.number,

      maxLength: 6,

      inputFormatters: [
        FilteringTextInputFormatter
            .digitsOnly,

        LengthLimitingTextInputFormatter(
          6,
        ),
      ],

      textAlign:
          TextAlign.center,

      style:
          const TextStyle(
        fontSize: 22,
        fontWeight:
            FontWeight.bold,
        letterSpacing: 8,
      ),

      decoration:
          InputDecoration(
        counterText: '',
        hintText: '••••••',

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
    );
  }
}
