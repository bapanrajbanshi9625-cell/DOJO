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
    // 2. BACKEND UID
    // ==========================================================

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'uid-missing',
        message:
            'Firebase UID was not found.',
      );
    }

    // ==========================================================
    // 3. VERIFIED PHONE NUMBER
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
    // 4. GET OR CREATE OWNER ID
    // ==========================================================
    //
    // Example:
    //
    // OWN26GM0001
    //
    // Owner ID is the BUSINESS ID.
    // Firebase UID remains backend-only.
    //
    // ==========================================================

    final String ownerId =
        await OwnerIdService.instance.getOrCreateOwnerId(
      uid: uid,
      phoneNumber: mobileNumber,
    );

    // ==========================================================
    // 5. CONVERT PET DATA
    // ==========================================================

    final List<Map<String, dynamic>> petData =
        pets.asMap().entries.map((entry) {
      return entry.value.toMap(entry.key);
    }).toList();

    // ==========================================================
    // 6. OWNER PROFILE REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        ownerProfileRef = _firestore
            .collection('ownerProfiles')
            .doc(ownerId);

    // ==========================================================
    // 7. CHECK EXISTING PROFILE
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
        // OWNER BUSINESS ID
        // ------------------------------------------------------

        'ownerId': ownerId,

        // ------------------------------------------------------
        // BACKEND AUTH UID
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
        //
        // Photo upload can be connected later.
        //
        // Don't overwrite an existing photo.
        //
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
        //
        // New owner starts active.
        // Later Admin can change this.
        //
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
        //
        // Only written for a new document.
        //
        if (!existingProfile.exists)
          'createdAt':
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
        message:
            'Owner ID was not found.',
      );
    }

    return await _firestore
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
        message:
            'User is not logged in.',
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
        message:
            'Owner ID was not found.',
      );
    }

    return await _firestore
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
