import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pet_data.dart';

class ProfileSetupService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static Future<void> saveProfile({
    required String ownerName,
    required String address,
    required List<PetData> pets,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-logged-in',
        message:
            'User is not logged in. Please verify your mobile number first.',
      );
    }

    final String uid = user.uid;

    final String mobileNumber =
        user.phoneNumber ?? '';

    if (mobileNumber.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'phone-number-missing',
        message:
            'Verified mobile number was not found.',
      );
    }

    final List<Map<String, dynamic>> petData =
        pets.asMap().entries.map((entry) {
      return entry.value.toMap(entry.key);
    }).toList();

    await _firestore
        .collection('users')
        .doc(uid)
        .set(
      {
        // Authentication
        'uid': uid,
        'mobileNumber': mobileNumber,

        // Owner
        'ownerName': ownerName.trim(),
        'address': address.trim(),

        // Pets
        'pets': petData,
        'petCount': pets.length,

        // Profile status
        'profileCompleted': true,

        // Timestamp
        'updatedAt':
            FieldValue.serverTimestamp(),

        // Only created if it doesn't already exist.
        'createdAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
