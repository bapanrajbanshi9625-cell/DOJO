// File location: lib/services/profile_setup_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

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
  // GET CURRENT LOCATION
  // ============================================================

  static Future<Position?> getCurrentLocation() async {
    // ----------------------------------------------------------
    // LOCATION SERVICE ENABLED?
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
        permission ==
            LocationPermission.deniedForever) {
      return null;
    }

    // ----------------------------------------------------------
    // CURRENT POSITION
    // ----------------------------------------------------------

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
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

    // Current location optional.
    double? latitude,
    double? longitude,
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
    // VERIFIED MOBILE NUMBER
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
    // OWNER ID
    // ----------------------------------------------------------

    String? ownerId =
        await OwnerIdService.instance
            .getExistingOwnerId(
      uid: uid,
    );

    ownerId ??=
        await OwnerIdService.instance
            .getOrCreateOwnerId(
      uid: uid,
      phoneNumber: phoneNumber,
    );

    ownerId =
        ownerId.trim();

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
    // OWNER PROFILE REFERENCE
    // ----------------------------------------------------------

    final DocumentReference<
        Map<String, dynamic>> ownerProfileRef =
        _firestore
            .collection(
              _ownerProfilesCollection,
            )
            .doc(ownerId);

    // ----------------------------------------------------------
    // PROFILE DATA
    // ----------------------------------------------------------

    final Map<String, dynamic> profileData = {
      // Identity
      'ownerId': ownerId,
      'authUid': uid,

      // Verified mobile
      'phone': phoneNumber,
      'mobileNumber': phoneNumber,

      // Owner
      'ownerName':
          ownerName.trim(),

      // Address
      'address':
          address.trim(),

      // Pets
      'pets':
          petData,

      // Status
      'profileCompleted': true,
      'isActive': true,
      'role': 'owner',

      // Time
      'updatedAt':
          FieldValue.serverTimestamp(),

      'profileCompletedAt':
          FieldValue.serverTimestamp(),
    };

    // ----------------------------------------------------------
    // CURRENT LOCATION
    // ----------------------------------------------------------
    //
    // Location only saved when available.
    //
    // latitude
    // longitude
    //
    // ownerLocation:
    // {
    //   latitude: ...,
    //   longitude: ...
    // }
    //
    // ----------------------------------------------------------

    if (latitude != null &&
        longitude != null) {
      profileData['latitude'] =
          latitude;

      profileData['longitude'] =
          longitude;

      profileData['ownerLocation'] =
          GeoPoint(
        latitude,
        longitude,
      );
    }

    // ----------------------------------------------------------
    // SAVE OWNER PROFILE
    // ----------------------------------------------------------

    await ownerProfileRef.set(
      profileData,
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
        'mobileNumber': phoneNumber,

        'role': 'owner',

        'ownerId': ownerId,

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

  static Future<bool>
      isProfileCompleted() async {
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
    // OWNER ID
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
    // OWNER PROFILE
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

    return data?['profileCompleted'] ==
        true;
  }

  // ============================================================
  // GET OWNER PROFILE
  // ============================================================

  static Future<
      DocumentSnapshot<
          Map<String, dynamic>>?>
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

  // ============================================================
  // GET OWNER LOCATION
  // ============================================================

  static Future<GeoPoint?>
      getOwnerLocation() async {
    final DocumentSnapshot<
        Map<String, dynamic>>?
        snapshot =
        await getOwnerProfile();

    if (snapshot == null ||
        !snapshot.exists) {
      return null;
    }

    final data =
        snapshot.data();

    final dynamic location =
        data?['ownerLocation'];

    if (location is GeoPoint) {
      return location;
    }

    final dynamic latitude =
        data?['latitude'];

    final dynamic longitude =
        data?['longitude'];

    if (latitude is num &&
        longitude is num) {
      return GeoPoint(
        latitude.toDouble(),
        longitude.toDouble(),
      );
    }

    return null;
  }
}
