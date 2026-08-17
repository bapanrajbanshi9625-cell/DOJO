import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pet_data.dart';
import 'owner_id_service.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // SAVE OWNER PROFILE
  // ============================================================

  static Future<void> saveProfile({
    required String ownerName,
    required String address,
    required List<PetData> pets,
  }) async {
    // ==========================================================
    // 1. CURRENT FIREBASE USER
    // ==========================================================

    final User? user = _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-logged-in',
        message:
            'User is not logged in. Please verify your mobile number first.',
      );
    }

    // ==========================================================
    // 2. FIREBASE UID
    // ==========================================================

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'uid-missing',
        message: 'Firebase UID was not found.',
      );
    }

    // ==========================================================
    // 3. VERIFIED PHONE
    // ==========================================================

    final String mobileNumber =
        user.phoneNumber?.trim() ?? '';

    if (mobileNumber.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'phone-number-missing',
        message:
            'Verified mobile number was not found.',
      );
    }

    // ==========================================================
    // 4. OWNER BUSINESS ID
    // ==========================================================

    final String ownerId =
        await OwnerIdService.instance.getOrCreateOwnerId(
      uid: uid,
      phoneNumber: mobileNumber,
    );

    if (ownerId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message: 'Owner ID could not be created.',
      );
    }

    // ==========================================================
    // 5. PET DATA
    // ==========================================================

    final List<Map<String, dynamic>> petData =
        pets.asMap().entries.map((entry) {
      return entry.value.toMap(entry.key);
    }).toList();

    // ==========================================================
    // 6. OWNER PROFILE REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        ownerProfileRef =
        _firestore
            .collection('ownerProfiles')
            .doc(ownerId);

    // ==========================================================
    // 7. GET EXISTING OWNER PROFILE
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        existingProfile =
        await ownerProfileRef.get();

    // ==========================================================
    // 8. SAVE OWNER PROFILE
    // ==========================================================

    await ownerProfileRef.set(
      {
        // ------------------------------------------------------
        // BUSINESS OWNER ID
        // ------------------------------------------------------

        'ownerId': ownerId,

        // ------------------------------------------------------
        // FIREBASE AUTH UID
        // ------------------------------------------------------

        'authUid': uid,

        // ------------------------------------------------------
        // MOBILE
        // ------------------------------------------------------

        'phone': mobileNumber,

        // ------------------------------------------------------
        // OWNER NAME
        // ------------------------------------------------------

        'fullName': ownerName.trim(),

        // ------------------------------------------------------
        // ADDRESS
        // ------------------------------------------------------

        'address': address.trim(),

        // ------------------------------------------------------
        // PETS
        // ------------------------------------------------------

        'pets': petData,

        // ------------------------------------------------------
        // PROFILE PHOTO
        // ------------------------------------------------------

        if (!existingProfile.exists ||
            existingProfile.data()?['profilePhoto'] == null)
          'profilePhoto': '',

        // ------------------------------------------------------
        // ROLE
        // ------------------------------------------------------

        'role': 'owner',

        // ------------------------------------------------------
        // ACTIVE STATUS
        // ------------------------------------------------------

        if (!existingProfile.exists)
          'isActive': true,

        // ------------------------------------------------------
        // PROFILE COMPLETED
        // ------------------------------------------------------

        'profileCompleted': true,

        // ------------------------------------------------------
        // UPDATED
        // ------------------------------------------------------

        'updatedAt':
            FieldValue.serverTimestamp(),

        // ------------------------------------------------------
        // CREATED
        // ------------------------------------------------------

        if (!existingProfile.exists)
          'createdAt':
              FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ==========================================================
    // 9. SYNC USERS/{UID}
    // ==========================================================
    //
    // SplashScreen currently checks:
    //
    // users/{Firebase UID}
    //
    // Therefore keep this document synchronized with the
    // ownerProfiles document.
    //
    // ==========================================================

    await _firestore
        .collection('users')
        .doc(uid)
        .set(
      {
        'uid': uid,
        'ownerId': ownerId,
        'phone': mobileNumber,
        'fullName': ownerName.trim(),
        'address': address.trim(),
        'role': 'owner',
        'profileCompleted': true,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // GET OWNER PROFILE
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>>
      getOwnerProfile({
    required String ownerId,
  }) async {
    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message: 'Owner ID was not found.',
      );
    }

    return _firestore
        .collection('ownerProfiles')
        .doc(cleanOwnerId)
        .get();
  }

  // ============================================================
  // GET CURRENT OWNER PROFILE
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>>
      getCurrentOwnerProfile() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'user-not-logged-in',
        message: 'User is not logged in.',
      );
    }

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: user.uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-not-found',
        message: 'Owner ID was not found.',
      );
    }

    return _firestore
        .collection('ownerProfiles')
        .doc(ownerId)
        .get();
  }

  // ============================================================
  // CHECK OWNER ACTIVE STATUS
  // ============================================================

  static Future<bool> isOwnerActive({
    required String ownerId,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection('ownerProfiles')
            .doc(ownerId)
            .get();

    if (!snapshot.exists) {
      return false;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    return data?['isActive'] == true;
  }
}
