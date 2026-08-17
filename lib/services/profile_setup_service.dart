import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pet_data.dart';
import 'owner_id_service.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final ProfileSetupService instance =
      ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  static const String _ownerProfilesCollection =
      'ownerProfiles';

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  static Future<void> saveProfile({
    required String ownerName,
    required String address,
    required List<PetData> pets,
  }) async {
    // ----------------------------------------------------------
    // CURRENT FIREBASE USER
    // ----------------------------------------------------------

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-authenticated',
        message:
            'User is not logged in. Please verify your mobile number first.',
      );
    }

    // ----------------------------------------------------------
    // UID
    // ----------------------------------------------------------

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-user',
        message: 'Firebase UID was not found.',
      );
    }

    // ----------------------------------------------------------
    // PHONE
    // ----------------------------------------------------------

    String phoneNumber =
        user.phoneNumber?.trim() ?? '';

    if (phoneNumber.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'phone-not-found',
        message:
            'Verified mobile number was not found.',
      );
    }

    // ----------------------------------------------------------
    // GET EXISTING OWNER ID
    // ----------------------------------------------------------

    String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    // ----------------------------------------------------------
    // CREATE OWNER ID IF MISSING
    // ----------------------------------------------------------

    ownerId ??=
        await OwnerIdService.instance
            .getOrCreateOwnerId(
      uid: uid,
      phoneNumber: phoneNumber,
    );

    ownerId = ownerId.trim();

    if (ownerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Owner ID could not be created.',
      );
    }

    // ----------------------------------------------------------
    // PET DATA
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> petData =
        pets.map((pet) {
      return {
        'name':
            pet.nameController.text.trim(),
        'age':
            pet.age,
        'breed':
            pet.breed,
        'behaviour':
            pet.behaviour,
      };
    }).toList();

    // ----------------------------------------------------------
    // OWNER PROFILE
    // ----------------------------------------------------------

    final DocumentReference<
        Map<String, dynamic>> ownerProfileRef =
        _firestore
            .collection(
              _ownerProfilesCollection,
            )
            .doc(ownerId);

    // ----------------------------------------------------------
    // SAVE PROFILE
    // ----------------------------------------------------------
    //
    // IMPORTANT:
    // profileCompleted = true
    //
    // Splash और OTP verification
    // इसी field को check करेंगे.
    // ----------------------------------------------------------

    await ownerProfileRef.set(
      {
        'ownerId': ownerId,
        'authUid': uid,
        'phone': phoneNumber,

        'ownerName': ownerName.trim(),
        'address': address.trim(),

        'pets': petData,

        'profileCompleted': true,
        'isActive': true,
        'role': 'owner',

        'updatedAt':
            FieldValue.serverTimestamp(),

        'profileCompletedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // UPDATE PHONE ACCOUNT
    // ----------------------------------------------------------

    await _firestore
        .collection('phoneAccounts')
        .doc(uid)
        .set(
      {
        'authUid': uid,
        'phone': phoneNumber,
        'role': 'owner',
        'ownerId': ownerId,
        'profileCompleted': true,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // CHECK PROFILE COMPLETED
  // ============================================================

  static Future<bool> isProfileCompleted() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // GET OWNER ID
    // ----------------------------------------------------------

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // GET OWNER PROFILE
    // ----------------------------------------------------------

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection(
              _ownerProfilesCollection,
            )
            .doc(ownerId)
            .get();

    if (!snapshot.exists) {
      return false;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    return data?['profileCompleted'] == true;
  }

  // ============================================================
  // GET OWNER PROFILE
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>?>
      getOwnerProfile() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      return null;
    }

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return null;
    }

    return _firestore
        .collection(
          _ownerProfilesCollection,
        )
        .doc(ownerId)
        .get();
  }
}
