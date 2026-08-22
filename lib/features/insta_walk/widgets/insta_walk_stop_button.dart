import 'package:flutter/material.dart';

class InstaWalkStopButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;

  const InstaWalkStopButton({
    super.key,
    this.loading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: Colors.black.withValues(alpha: .12),
          foregroundColor: Colors.white,
          side: BorderSide(
            color: Colors.white.withValues(alpha: .22),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stop_circle_outlined,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Stop Insta Walk',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
