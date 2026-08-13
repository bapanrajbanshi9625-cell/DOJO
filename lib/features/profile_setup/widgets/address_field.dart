import 'package:flutter/material.dart';

class AddressField extends StatelessWidget {
  final TextEditingController controller;

  const AddressField({
    super.key,
    required this.controller,
  });

  static const Color orange =
      Color(0xFFF4511E);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 4,
      textCapitalization:
          TextCapitalization.sentences,
      decoration: InputDecoration(
        alignLabelWithHint: true,
        prefixIcon: const Padding(
          padding:
              EdgeInsets.only(bottom: 65),
          child: Icon(
            Icons.location_on_outlined,
            color: orange,
          ),
        ),
        hintText:
            'Enter your address (optional)',
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
    );
  }
}
