import 'package:flutter/material.dart';

import '../../../models/pet_data.dart';
import 'profile_text_field.dart';
import 'profile_selection_field.dart';

class PetCard extends StatelessWidget {
  final PetData pet;
  final int index;
  final int totalPets;
  final VoidCallback onRemove;
  final VoidCallback onAgeTap;
  final VoidCallback onBreedTap;
  final VoidCallback onBehaviourTap;

  const PetCard({
    super.key,
    required this.pet,
    required this.index,
    required this.totalPets,
    required this.onRemove,
    required this.onAgeTap,
    required this.onBreedTap,
    required this.onBehaviourTap,
  });

  static const Color orange =
      Color(0xFFF4511E);

  static const Color lightOrange =
      Color(0xFFFFF1E8);

  @override
  Widget build(BuildContext context) {
    final petNumber = index + 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.045),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                    const BoxDecoration(
                  color: lightOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  color: orange,
                  size: 23,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  'Pet $petNumber',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              if (totalPets > 1)
                TextButton.icon(
                  onPressed: onRemove,
                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        Colors.red.shade600,
                  ),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                  ),
                  label: const Text(
                    'Remove',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 17),

          ProfileTextField(
            controller:
                pet.nameController,
            label: 'Pet Name',
            hint: 'Enter pet name',
            icon: Icons.pets_rounded,
          ),

          const SizedBox(height: 17),

          ProfileSelectionField(
            label: 'Pet Age',
            hint: 'Choose pet age',
            icon: Icons.cake_outlined,
            value: pet.age,
            onTap: onAgeTap,
          ),

          const SizedBox(height: 17),

          ProfileSelectionField(
            label: 'Breed',
            hint: 'Choose breed',
            icon: Icons.pets_outlined,
            value: pet.breed,
            onTap: onBreedTap,
          ),

          const SizedBox(height: 17),

          ProfileSelectionField(
            label: 'Behaviour',
            hint: 'Choose behaviour',
            icon:
                Icons.favorite_border_rounded,
            value: pet.behaviour,
            onTap: onBehaviourTap,
          ),
        ],
      ),
    );
  }
}
