import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../screens/address_screen.dart';
import '../services/insta_walk_search_service.dart';

class InstaWalkFindWalker {
  InstaWalkFindWalker({
    required this.context,
    required this.service,
    required this.isSearching,
    required this.isCheckingAddress,
    required this.isRecovering,
    required this.isStopping,
    required this.setCheckingAddress,
    required this.setSearchFinished,
    required this.setOwnerPosition,
    required this.setPetName,
    required this.startSearch,
    required this.message,
  });

  final BuildContext context;
  final InstaWalkSearchService service;

  final bool isSearching;
  final bool isCheckingAddress;
  final bool isRecovering;
  final bool isStopping;

  final void Function(bool value) setCheckingAddress;
  final void Function(bool value) setSearchFinished;
  final void Function(Position position) setOwnerPosition;
  final void Function(String value) setPetName;

  final Future<void> Function({
    required String ownerId,
    required String ownerName,
    required String address,
    required Position position,
  }) startSearch;

  final void Function(String text) message;

  // ============================================================
  // FIND WALKER
  // ============================================================

  Future<void> findWalker() async {
    if (isSearching ||
        isCheckingAddress ||
        isRecovering ||
        isStopping) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      message('Please login first.');
      return;
    }

    setCheckingAddress(true);
    setSearchFinished(false);

    try {
      // --------------------------------------------------------
      // OWNER PROFILE
      // --------------------------------------------------------

      final QueryDocumentSnapshot<
          Map<String, dynamic>>? ownerDoc =
          await service.findOwnerProfile();

      if (ownerDoc == null) {
        setCheckingAddress(false);

        message(
          'Owner profile not found. Please complete your profile.',
        );

        return;
      }

      final Map<String, dynamic> data =
          ownerDoc.data();

      // --------------------------------------------------------
      // OWNER ID
      // --------------------------------------------------------

      final String ownerId =
          _readFirstString(
        data,
        const [
          'ownerId',
          'Owner ID',
        ],
      );

      if (ownerId.isEmpty) {
        setCheckingAddress(false);
        message('Owner ID not found.');
        return;
      }

      // --------------------------------------------------------
      // PET NAME
      // --------------------------------------------------------

      String petName =
          _readFirstString(
        data,
        const [
          'petName',
          'Pet Name',
          'dogName',
          'Dog Name',
        ],
      );

      if (petName.isEmpty) {
        petName = 'Your Pet';
      }

      setPetName(petName);

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      final String address =
          _readFirstString(
        data,
        const [
          'address',
          'Adress',
          'Address',
        ],
      );

      // --------------------------------------------------------
      // ADDRESS MISSING
      // --------------------------------------------------------

      if (address.isEmpty) {
        setCheckingAddress(false);

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AddressScreen(),
          ),
        );

        setCheckingAddress(false);

        return;
      }

      // --------------------------------------------------------
      // OWNER NAME
      // --------------------------------------------------------

      String ownerName =
          _readFirstString(
        data,
        const [
          'fullName',
          'Full Name',
          'ownerName',
          'name',
        ],
      );

      if (ownerName.isEmpty) {
        ownerName = 'Dog Owner';
      }

      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

      final Position? position =
          await _getLocation();

      if (position == null) {
        setCheckingAddress(false);
        return;
      }

      setOwnerPosition(position);

      // --------------------------------------------------------
      // START SEARCH
      // --------------------------------------------------------

      await startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        position: position,
      );
    } catch (e) {
      debugPrint(
        'Insta Walk find walker error: $e',
      );

      setCheckingAddress(false);

      message(
        'Unable to start Insta Walk.',
      );
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<Position?> _getLocation() async {
    try {
      final bool enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        message(
          'Please turn on location service.',
        );

        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        message(
          'Location permission is required.',
        );

        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint(
        'Location error: $e',
      );

      message(
        'Unable to get your current location.',
      );

      return null;
    }
  }

  // ============================================================
  // READ STRING
  // ============================================================

  String _readFirstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String result =
          value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }
}
