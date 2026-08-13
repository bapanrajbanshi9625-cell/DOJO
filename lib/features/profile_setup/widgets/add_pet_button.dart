import 'package:flutter/material.dart';

class AddPetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddPetButton({
    super.key,
    required this.onPressed,
  });

  static const Color orange =
      Color(0xFFF4511E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style:
            OutlinedButton.styleFrom(
          foregroundColor: orange,
          side: const BorderSide(
            color: orange,
            width: 1.4,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(
          Icons.add_rounded,
          size: 23,
        ),
        label: const Text(
          'Add Pet',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
