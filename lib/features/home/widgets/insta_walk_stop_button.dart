import 'package:flutter/material.dart';

class InstaWalkStopButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const InstaWalkStopButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  static const Color mintGreen = Color(0xFFB8F2D0);
  static const Color darkMint = Color(0xFF176B45);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    darkMint,
                  ),
                ),
              )
            : const Icon(
                Icons.stop_circle_outlined,
                size: 20,
              ),
        label: Text(
          loading ? 'STOPPING...' : 'STOP SEARCH',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: mintGreen,
          foregroundColor: darkMint,
          disabledBackgroundColor: mintGreen,
          disabledForegroundColor: darkMint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
