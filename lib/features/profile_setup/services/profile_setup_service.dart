// File location:
// lib/features/profile_setup/services/profile_setup_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../models/pet_data.dart';
import '../../../services/owner_id_service.dart';

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
  // GET CURRENT LOCATION
  // ============================================================

  static Future<Position?> _getCurrentLocation() async {
    try {
      // ----------------------------------------------------------
      // LOCATION SERVICE
      // ----------------------------------------------------------

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      // ----------------------------------------------------------
      // PERMISSION
      // ----------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // ----------------------------------------------------------
      // CURRENT POSITION
      // ----------------------------------------------------------
      //
      // IMPORTANT:
      // This project uses the Geolocator API where
      // desiredAccuracy is supported.
      //
      // ----------------------------------------------------------

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Location failure should NOT stop
      // profile saving.
      return null;
    }
  }

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
    // AUTH UID
    // ----------------------------------------------------------

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        code: 'invalid-user',
        message:
            'Firebase UID was not found.',
      );
    }

    // ----------------------------------------------------------
    // MAIN / VERIFIED MOBILE NUMBER
    // ----------------------------------------------------------

    final String phoneNumber =
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
        await OwnerIdService.instance.getExistingOwnerId(
      uid: uid,
    );

    // ----------------------------------------------------------
    // CREATE OWNER ID IF MISSING
    // ----------------------------------------------------------

    ownerId ??=
        await OwnerIdService.instance.getOrCreateOwnerId(
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

    // ==========================================================
    // CURRENT GPS LOCATION
    // ==========================================================

    final Position? position =
        await _getCurrentLocation();

    // ==========================================================
    // PET DATA
    // ==========================================================

    final List<Map<String, dynamic>> petData =
        pets.map((pet) {
      return <String, dynamic>{
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

    // ==========================================================
    // OWNER PROFILE REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        ownerProfileRef =
        _firestore
            .collection(
              _ownerProfilesCollection,
            )
            .doc(ownerId);

    // ==========================================================
    // OWNER PROFILE DATA
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      // --------------------------------------------------------
      // OWNER IDENTITY
      // --------------------------------------------------------

      'ownerId':
          ownerId,

      'authUid':
          uid,

      'phone':
          phoneNumber,

      'mainPhone':
          phoneNumber,

      'ownerName':
          ownerName.trim(),

      // --------------------------------------------------------
      // MANUAL ADDRESS
      // --------------------------------------------------------

      'address':
          address.trim(),

      // --------------------------------------------------------
      // PETS
      // --------------------------------------------------------

      'pets':
          petData,

      // --------------------------------------------------------
      // ROLE / STATUS
      // --------------------------------------------------------

      'role':
          'owner',

      'isActive':
          true,

      'profileCompleted':
          true,

      // --------------------------------------------------------
      // PROFILE TIMESTAMP
      // --------------------------------------------------------

      'updatedAt':
          FieldValue.serverTimestamp(),

      'profileCompletedAt':
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // CURRENT LOCATION
    // ==========================================================
    //
    // Permission मिलने पर latitude, longitude और location
    // Firestore में save होंगे.
    //
    // Permission न मिलने पर profile फिर भी save होगी.
    //
    // ==========================================================

    if (position != null) {
      profileData['latitude'] =
          position.latitude;

      profileData['longitude'] =
          position.longitude;

      profileData['location'] =
          <String, dynamic>{
        'latitude':
            position.latitude,
        'longitude':
            position.longitude,
      };

      profileData['locationAccuracy'] =
          position.accuracy;

      profileData['locationUpdatedAt'] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // SAVE OWNER PROFILE
    // ==========================================================

    await ownerProfileRef.set(
      profileData,
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // UPDATE PHONE ACCOUNT
    // ==========================================================

    await _firestore
        .collection('phoneAccounts')
        .doc(uid)
        .set(
      <String, dynamic>{
        'authUid':
            uid,

        'phone':
            phoneNumber,

        'mainPhone':
            phoneNumber,

        'role':
            'owner',

        'ownerId':
            ownerId,

        'profileCompleted':
            true,

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
        await OwnerIdService.instance.getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // GET OWNER PROFILE
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
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
        await OwnerIdService.instance.getExistingOwnerId(
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

  // ============================================================
  // UPDATE CURRENT OWNER LOCATION
  // ============================================================
  //
  // Home/Profile से current location
  // refresh करने के लिए.
  //
  // ============================================================

  static Future<void> updateCurrentLocation() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
      return;
    }

    final String? ownerId =
        await OwnerIdService.instance.getExistingOwnerId(
      uid: uid,
    );

    if (ownerId == null ||
        ownerId.trim().isEmpty) {
      return;
    }

    final Position? position =
        await _getCurrentLocation();

    if (position == null) {
      return;
    }

    await _firestore
        .collection(
          _ownerProfilesCollection,
        )
        .doc(ownerId)
        .set(
      <String, dynamic>{
        'latitude':
            position.latitude,

        'longitude':
            position.longitude,

        'location':
            <String, dynamic>{
          'latitude':
              position.latitude,
          'longitude':
              position.longitude,
        },

        'locationAccuracy':
            position.accuracy,

        'locationUpdatedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}
