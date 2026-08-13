import 'package:flutter/material.dart';

class PetData {
  final TextEditingController nameController =
      TextEditingController();

  String? age;
  String? breed;
  String? behaviour;

  Map<String, dynamic> toMap(int index) {
    return {
      'petNumber': index + 1,
      'name': nameController.text.trim(),
      'age': age,
      'breed': breed,
      'behaviour': behaviour,
    };
  }

  void dispose() {
    nameController.dispose();
  }
}
