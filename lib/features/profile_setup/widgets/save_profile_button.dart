import 'package:flutter/material.dart';

class SaveProfileButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onPressed;

  const SaveProfileButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
  });

  static const Color orange =
      Color(0xFFF4511E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isSaving
            ? null
            : onPressed,
        style:
            ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              orange.withOpacity(0.55),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 23,
                height: 23,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save & Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
