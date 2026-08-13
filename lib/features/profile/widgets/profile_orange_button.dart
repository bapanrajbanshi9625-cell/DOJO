import 'package:flutter/material.dart';

class ProfileOrangeButton
    extends StatelessWidget {
  static const Color orange =
      Color(0xFFF4511E);

  final String text;
  final VoidCallback onPressed;

  const ProfileOrangeButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,

      child: ElevatedButton(
        onPressed: onPressed,

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              orange,

          foregroundColor:
              Colors.white,

          elevation: 0,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),

        child: Text(
          text,

          style:
              const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
