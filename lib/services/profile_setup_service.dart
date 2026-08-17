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
    // 2. FIREBASE AUTH UID
    // ==========================================================

    final String authUid = user.uid.trim();

    if (authUid.isEmpty) {
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
    // 4. GET / CREATE BUSINESS OWNER ID
    // ==========================================================
    //
    // Example:
    //
    // Firebase UID:
    // abc123xyz...
    //
    // Business Owner ID:
    // OWN26GM0001
    //
    // Firebase UID = backend authentication identity
    // Owner ID    = business identity
    //
    // ==========================================================

    final String ownerId =
        (await OwnerIdService.instance.getOrCreateOwnerId(
      uid: authUid,
      phoneNumber: mobileNumber,
    ))
        .trim();

    if (ownerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-missing',
        message:
            'Business Owner ID could not be created.',
      );
    }

    // ==========================================================
    // 5. CONVERT PET DATA
    // ==========================================================

    final List<Map<String, dynamic>> petData =
        pets.asMap().entries.map((entry) {
      return entry.value.toMap(entry.key);
    }).toList();

    // ==========================================================
    // 6. OWNER PROFILE DOCUMENT
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        ownerProfileRef =
        _firestore
            .collection('ownerProfiles')
            .doc(ownerId);

    // ==========================================================
    // 7. CHECK EXISTING PROFILE
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        existingProfile =
        await ownerProfileRef.get();

    final Map<String, dynamic>? existingData =
        existingProfile.data();

    // ==========================================================
    // 8. SAVE OWNER PROFILE
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      // --------------------------------------------------------
      // BUSINESS OWNER ID
      // --------------------------------------------------------

      'ownerId': ownerId,

      // --------------------------------------------------------
      // FIREBASE AUTH UID
      // --------------------------------------------------------

      'authUid': authUid,

      // --------------------------------------------------------
      // MOBILE
      // --------------------------------------------------------

      'phone': mobileNumber,

      // --------------------------------------------------------
      // OWNER NAME
      // --------------------------------------------------------

      'fullName': ownerName.trim(),

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      'address': address.trim(),

      // --------------------------------------------------------
      // PETS
      // --------------------------------------------------------

      'pets': petData,

      // --------------------------------------------------------
      // ROLE
      // --------------------------------------------------------

      'role': 'owner',

      // --------------------------------------------------------
      // PROFILE COMPLETED
      // --------------------------------------------------------

      'profileCompleted': true,

      // --------------------------------------------------------
      // UPDATED
      // --------------------------------------------------------

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // 9. PROFILE PHOTO
    // ==========================================================
    //
    // Existing photo must never be accidentally deleted.
    //
    // ==========================================================

    final dynamic existingPhoto =
        existingData?['profilePhoto'];

    if (!existingProfile.exists ||
        existingPhoto == null) {
      profileData['profilePhoto'] = '';
    }

    // ==========================================================
    // 10. ACTIVE STATUS
    // ==========================================================

    if (!existingProfile.exists) {
      profileData['isActive'] = true;
    }

    // ==========================================================
    // 11. CREATED AT
    // ==========================================================

    if (!existingProfile.exists) {
      profileData['createdAt'] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // 12. WRITE
    // ==========================================================

    await ownerProfileRef.set(
      profileData,
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // GET OWNER PROFILE BY BUSINESS OWNER ID
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

    return _firestore
        .collection('ownerProfiles')
        .doc(cleanOwnerId)
        .get();
  }

  // ============================================================
  // GET CURRENT BUSINESS OWNER ID
  // ============================================================

  static Future<String?> getCurrentOwnerId() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String authUid =
        user.uid.trim();

    if (authUid.isEmpty) {
      return null;
    }

    final String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: authUid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return null;
    }

    return ownerId.trim();
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
        await getCurrentOwnerId();

    if (ownerId == null ||
        ownerId.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'owner-id-not-found',
        message:
            'Owner ID was not found.',
      );
    }

    return _firestore
        .collection('ownerProfiles')
        .doc(ownerId)
        .get();
  }

  // ============================================================
  // CHECK OWNER PROFILE COMPLETED
  // ============================================================

  static Future<bool> isOwnerProfileCompleted() async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await getCurrentOwnerProfile();

      if (!snapshot.exists) {
        return false;
      }

      return snapshot.data()?['profileCompleted'] == true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CHECK OWNER ACTIVE STATUS
  // ============================================================

  static Future<bool> isOwnerActive({
    required String ownerId,
  }) async {
    final String cleanOwnerId =
        ownerId.trim();

    if (cleanOwnerId.isEmpty) {
      return false;
    }

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection('ownerProfiles')
            .doc(cleanOwnerId)
            .get();

    if (!snapshot.exists) {
      return false;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    return data?['isActive'] == true;
  }
}
