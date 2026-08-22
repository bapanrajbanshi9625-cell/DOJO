// File location: lib/screens/address_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants/app_colors.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController _flatController =
      TextEditingController();

  final TextEditingController _addressLine1Controller =
      TextEditingController();

  final TextEditingController _addressLine2Controller =
      TextEditingController();

  final TextEditingController _areaController =
      TextEditingController();

  final TextEditingController _cityController =
      TextEditingController();

  final TextEditingController _stateController =
      TextEditingController();

  final TextEditingController _pinCodeController =
      TextEditingController();

  // =========================================================
  // FIREBASE
  // =========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // STATE
  // =========================================================

  bool _loading = true;
  bool _saving = false;
  bool _gettingLocation = false;

  DocumentReference<Map<String, dynamic>>? _ownerProfileRef;

  final List<Map<String, dynamic>> _savedAddresses =
      <Map<String, dynamic>>[];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  // =========================================================
  // FIND OWNER PROFILE
  // =========================================================

  Future<DocumentReference<Map<String, dynamic>>?>
      _findOwnerProfile() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> query =
          await _firestore
              .collection('ownerProfiles')
              .where(
                'authUid',
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return query.docs.first.reference;
    } on FirebaseException catch (e) {
      debugPrint(
        'FIND OWNER PROFILE FIREBASE ERROR: '
        '${e.code} - ${e.message}',
      );
      rethrow;
    }
  }

  // =========================================================
  // LOAD ADDRESS
  // =========================================================

  Future<void> _loadAddress() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>>?
          ownerRef = await _findOwnerProfile();

      if (ownerRef == null) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }

        _showMessage(
          'Owner profile not found.',
        );
        return;
      }

      _ownerProfileRef = ownerRef;

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await ownerRef.get();

      if (!snapshot.exists) {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }

        _showMessage(
          'Owner profile not found.',
        );
        return;
      }

      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      // =====================================================
      // READ STRUCTURED ADDRESS
      // =====================================================

      _flatController.text =
          _readString(
        data,
        'flatNumber',
      );

      _addressLine1Controller.text =
          _readString(
        data,
        'addressLine1',
      );

      _addressLine2Controller.text =
          _readString(
        data,
        'addressLine2',
      );

      _areaController.text =
          _readString(
        data,
        'area',
      );

      _cityController.text =
          _readString(
        data,
        'city',
      );

      _stateController.text =
          _readString(
        data,
        'state',
      );

      // New field first, old field as fallback.
      _pinCodeController.text =
          _readString(
        data,
        'pincode',
      ).isNotEmpty
              ? _readString(
                  data,
                  'pincode',
                )
              : _readString(
                  data,
                  'Pincode',
                );

      // =====================================================
      // OLD ADDRESS COMPATIBILITY
      // =====================================================

      String oldAddress =
          _readString(
        data,
        'address',
      ).trim();

      if (oldAddress.isEmpty) {
        oldAddress =
            _readString(
          data,
          'Adress',
        ).trim();
      }

      // If structured address fields are empty,
      // keep the old complete address in Address Line 1.
      if (_addressLine1Controller.text
              .trim()
              .isEmpty &&
          oldAddress.isNotEmpty) {
        _addressLine1Controller.text =
            oldAddress;
      }

      // =====================================================
      // LOAD SAVED ADDRESSES
      // =====================================================

      _savedAddresses.clear();

      final dynamic firebaseAddresses =
          data['savedAddresses'];

      if (firebaseAddresses is List) {
        for (final dynamic item
            in firebaseAddresses) {
          if (item is Map) {
            _savedAddresses.add(
              Map<String, dynamic>.from(
                item,
              ),
            );
          }
        }
      }

      // =====================================================
      // BACKWARD COMPATIBILITY
      // =====================================================

      if (_savedAddresses.isEmpty &&
          oldAddress.isNotEmpty) {
        _savedAddresses.add(
          <String, dynamic>{
            'id': 'address_1',
            'title': 'Home',
            'address': oldAddress,
            'flatNumber':
                _readString(
              data,
              'flatNumber',
            ),
            'addressLine1':
                _readString(
              data,
              'addressLine1',
            ),
            'addressLine2':
                _readString(
              data,
              'addressLine2',
            ),
            'area':
                _readString(
              data,
              'area',
            ),
            'city':
                _readString(
              data,
              'city',
            ),
            'state':
                _readString(
              data,
              'state',
            ),
            'pincode':
                _readString(
                  data,
                  'pincode',
                ).isNotEmpty
                    ? _readString(
                        data,
                        'pincode',
                      )
                    : _readString(
                        data,
                        'Pincode',
                      ),
          },
        );
      }

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'ADDRESS LOAD FIREBASE ERROR: '
        '${e.code} - ${e.message}',
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });

        _showMessage(
          e.code == 'permission-denied'
              ? 'You do not have permission to read addresses.'
              : 'Unable to load addresses.',
        );
      }
    } catch (e) {
      debugPrint(
        'ADDRESS LOAD ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });

        _showMessage(
          'Unable to load addresses.',
        );
      }
    }
  }

  // =========================================================
  // SAFE FIRESTORE STRING READER
  // =========================================================

  String _readString(
    Map<String, dynamic> data,
    String key,
  ) {
    final dynamic value = data[key];

    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // =========================================================
  // CURRENT LOCATION
  // =========================================================

  Future<void> _useCurrentLocation() async {
    if (_gettingLocation || _saving) {
      return;
    }

    setState(() {
      _gettingLocation = true;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _gettingLocation = false;
          });
        }

        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _gettingLocation = false;
          });
        }

        _showMessage(
          'Location permission is required.',
        );
        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _gettingLocation = false;
          });
        }

        _showLocationPermissionDialog();
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      // =====================================================
      // REVERSE GEOCODING
      // =====================================================

      final List<Placemark> placemarks =
          await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        if (mounted) {
          setState(() {
            _gettingLocation = false;
          });
        }

        _showMessage(
          'Location detected, but address details could not be found.',
        );
        return;
      }

      final Placemark place =
          placemarks.first;

      final String street =
          place.street?.trim() ?? '';

      final String subLocality =
          place.subLocality?.trim() ?? '';

      final String locality =
          place.locality?.trim() ?? '';

      final String administrativeArea =
          place.administrativeArea?.trim() ?? '';

      final String postalCode =
          place.postalCode?.trim() ?? '';

      if (street.isNotEmpty) {
        _addressLine1Controller.text =
            street;
      }

      if (subLocality.isNotEmpty) {
        _areaController.text =
            subLocality;
      } else if (locality.isNotEmpty) {
        _areaController.text =
            locality;
      }

      if (locality.isNotEmpty) {
        _cityController.text =
            locality;
      }

      if (administrativeArea.isNotEmpty) {
        _stateController.text =
            administrativeArea;
      }

      if (postalCode.isNotEmpty) {
        _pinCodeController.text =
            postalCode;
      }

      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }

      _showMessage(
        'Current location detected. Please verify the address and save.',
      );
    } catch (e) {
      debugPrint(
        'CURRENT LOCATION ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }

      _showMessage(
        'Unable to detect current location.',
      );
    }
  }

  // =========================================================
  // LOCATION SERVICE DIALOG
  // =========================================================

  void _showLocationServiceDialog() {
    showDialog<void>(
      context: context,
      builder:
          (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Location is Off',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Please turn on your device location to automatically detect your address.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                Geolocator
                    .openLocationSettings();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Turn On',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // LOCATION PERMISSION DIALOG
  // =========================================================

  void _showLocationPermissionDialog() {
    showDialog<void>(
      context: context,
      builder:
          (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Location Permission Needed',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'Location permission was permanently denied. Please enable it from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                Geolocator
                    .openAppSettings();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
              ),
              child: const Text(
                'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // BUILD FULL ADDRESS
  // =========================================================

  String _buildFullAddress({
    required String flat,
    required String line1,
    required String line2,
    required String area,
    required String city,
    required String state,
    required String pin,
  }) {
    final List<String> parts =
        <String>[];

    if (flat.isNotEmpty) {
      parts.add(flat);
    }

    if (line1.isNotEmpty) {
      parts.add(line1);
    }

    if (line2.isNotEmpty) {
      parts.add(line2);
    }

    if (area.isNotEmpty) {
      parts.add(area);
    }

    if (city.isNotEmpty) {
      parts.add(city);
    }

    if (state.isNotEmpty) {
      parts.add(state);
    }

    if (pin.isNotEmpty) {
      parts.add(pin);
    }

    return parts.join(', ');
  }

  // =========================================================
  // SAVE ADDRESS
  // =========================================================

  Future<void> _saveAddress() async {
    if (_saving) {
      return;
    }

    final String flat =
        _flatController.text.trim();

    final String line1 =
        _addressLine1Controller.text.trim();

    final String line2 =
        _addressLine2Controller.text.trim();

    final String area =
        _areaController.text.trim();

    final String city =
        _cityController.text.trim();

    final String state =
        _stateController.text.trim();

    final String pin =
        _pinCodeController.text.trim();

    // =====================================================
    // VALIDATION
    // =====================================================

    if (line1.isEmpty) {
      _showMessage(
        'Please enter Address Line 1.',
      );
      return;
    }

    if (area.isEmpty) {
      _showMessage(
        'Please enter your area or locality.',
      );
      return;
    }

    if (city.isEmpty) {
      _showMessage(
        'Please enter your city.',
      );
      return;
    }

    if (state.isEmpty) {
      _showMessage(
        'Please enter your state.',
      );
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _showMessage(
        'Please enter a valid 6-digit PIN code.',
      );
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // =====================================================
      // FIND EXISTING OWNER PROFILE
      // =====================================================

      DocumentReference<Map<String, dynamic>>?
          ownerRef = _ownerProfileRef;

      ownerRef ??= await _findOwnerProfile();

      if (ownerRef == null) {
        if (mounted) {
          setState(() {
            _saving = false;
          });
        }

        _showMessage(
          'Owner profile not found.',
        );
        return;
      }

      _ownerProfileRef = ownerRef;

      // =====================================================
      // FULL ADDRESS
      // =====================================================

      final String fullAddress =
          _buildFullAddress(
        flat: flat,
        line1: line1,
        line2: line2,
        area: area,
        city: city,
        state: state,
        pin: pin,
      );

      // =====================================================
      // ADDRESS OBJECT
      // =====================================================

      final Map<String, dynamic> newAddress =
          <String, dynamic>{
        'id': _savedAddresses.isEmpty
            ? 'address_1'
            : (_savedAddresses.first['id']
                    ?.toString() ??
                'address_1'),
        'title': _savedAddresses.isEmpty
            ? 'Home'
            : (_savedAddresses.first['title']
                    ?.toString() ??
                'Home'),
        'address': fullAddress,
        'flatNumber': flat,
        'addressLine1': line1,
        'addressLine2': line2,
        'area': area,
        'city': city,
        'state': state,
        'pincode': pin,
      };

      // =====================================================
      // SAVED ADDRESSES
      // =====================================================

      final List<Map<String, dynamic>>
          addresses =
          _savedAddresses
              .map(
                (Map<String, dynamic> item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

      if (addresses.isEmpty) {
        addresses.add(newAddress);
      } else {
        addresses[0] = newAddress;
      }

      // =====================================================
      // OWNER PROFILE UPDATE
      //
      // IMPORTANT:
      // merge:true means existing fields such as:
      // ownerId
      // ownerName
      // pets
      // phone
      // profileCompleted
      // role
      // createdAt
      // etc.
      // WILL NOT BE DELETED.
      // =====================================================

      await ownerRef.set(
        <String, dynamic>{
          'authUid': user.uid,

          // Complete address
          'address': fullAddress,

          // Structured address
          'flatNumber': flat,
          'addressLine1': line1,
          'addressLine2': line2,
          'area': area,
          'city': city,
          'state': state,
          'pincode': pin,

          // Saved address
          'savedAddresses': addresses,

          // Timestamp
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // =====================================================
      // USERS SYNC
      // =====================================================

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        <String, dynamic>{
          'address': fullAddress,
          'flatNumber': flat,
          'addressLine1': line1,
          'addressLine2': line2,
          'area': area,
          'city': city,
          'state': state,
          'pincode': pin,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // =====================================================
      // UPDATE LOCAL STATE
      // =====================================================

      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses
          ..clear()
          ..addAll(addresses);

        _saving = false;
      });

      _showMessage(
        'Address saved successfully.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'ADDRESS SAVE FIREBASE ERROR: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        e.code == 'permission-denied'
            ? 'You do not have permission to save this address.'
            : 'Unable to save address.',
      );
    } catch (e) {
      debugPrint(
        'ADDRESS SAVE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      _showMessage(
        'Unable to save address.',
      );
    }
  }

  // =========================================================
  // SELECT ADDRESS
  // =========================================================

  void _selectAddress(
    Map<String, dynamic> address,
  ) {
    Navigator.pop(
      context,
      <String, dynamic>{
        'selected': true,
        ...address,
      },
    );
  }

  // =========================================================
  // DELETE ADDRESS
  // =========================================================

  Future<void> _deleteAddress(
    int index,
  ) async {
    if (index < 0 ||
        index >= _savedAddresses.length) {
      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Address?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          content: const Text(
            'This address will be removed from your saved addresses.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final List<Map<String, dynamic>>
          addresses =
          _savedAddresses
              .map(
                (Map<String, dynamic> item) =>
                    Map<String, dynamic>.from(
                  item,
                ),
              )
              .toList();

      addresses.removeAt(index);

      if (_ownerProfileRef != null) {
        await _ownerProfileRef!.set(
          <String, dynamic>{
            'savedAddresses':
                addresses,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _savedAddresses
          ..clear()
          ..addAll(addresses);
      });

      _showMessage(
        'Address deleted.',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'DELETE ADDRESS FIREBASE ERROR: '
        '${e.code} - ${e.message}',
      );

      _showMessage(
        e.code == 'permission-denied'
            ? 'You do not have permission to delete this address.'
            : 'Unable to delete address.',
      );
    } catch (e) {
      debugPrint(
        'DELETE ADDRESS ERROR: $e',
      );

      _showMessage(
        'Unable to delete address.',
      );
    }
  }

  // =========================================================
  // EDIT ADDRESS
  // =========================================================

  void _editAddress(
    Map<String, dynamic> address,
  ) {
    _flatController.text =
        address['flatNumber']?.toString() ?? '';

    _addressLine1Controller.text =
        address['addressLine1']?.toString() ?? '';

    _addressLine2Controller.text =
        address['addressLine2']?.toString() ?? '';

    _areaController.text =
        address['area']?.toString() ?? '';

    _cityController.text =
        address['city']?.toString() ?? '';

    _stateController.text =
        address['state']?.toString() ?? '';

    _pinCodeController.text =
        address['pincode']?.toString() ??
            address['Pincode']?.toString() ??
            '';

    _showMessage(
      'Address loaded. Update the details and save.',
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          backgroundColor:
              AppColors.navy,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _flatController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Choose Walking Address',
          style: TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    AppColors.primary,
              ),
            )
          : SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildBookingHeader(),

                  const SizedBox(
                    height: 18,
                  ),

                  _buildCurrentLocationCard(),

                  const SizedBox(
                    height: 24,
                  ),

                  if (_savedAddresses
                      .isNotEmpty) ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Saved Addresses',
                            style: TextStyle(
                              color:
                                  AppColors.navy,
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withValues(
                              alpha: .10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            '${_savedAddresses.length}',
                            style:
                                const TextStyle(
                              color:
                                  AppColors.primary,
                              fontWeight:
                                  FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      'Tap an address to use it for your booking.',
                      style: TextStyle(
                        color: AppColors.slate
                            .withValues(
                          alpha: .75,
                        ),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    ...List.generate(
                      _savedAddresses.length,
                      (int index) {
                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 12,
                          ),
                          child:
                              _buildSavedAddressCard(
                            index,
                            _savedAddresses[
                                index],
                          ),
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),
                  ],

                  _buildSectionTitle(
                    'Add New Address',
                    'Enter your walking location.',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  _buildField(
                    controller:
                        _flatController,
                    label:
                        'Flat / House No.',
                    hint:
                        'Flat 204 / House No. 12',
                    icon:
                        Icons.home_outlined,
                    requiredField:
                        false,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _buildField(
                    controller:
                        _addressLine1Controller,
                    label:
                        'Address Line 1',
                    hint:
                        'Street / Road / Building',
                    icon:
                        Icons.location_on_outlined,
                    maxLines: 2,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _buildField(
                    controller:
                        _addressLine2Controller,
                    label:
                        'Address Line 2 / Landmark',
                    hint:
                        'Nearby place / landmark',
                    icon:
                        Icons.signpost_outlined,
                    requiredField:
                        false,
                    maxLines: 2,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _buildField(
                    controller:
                        _areaController,
                    label:
                        'Area / Locality',
                    hint:
                        'Area or locality',
                    icon:
                        Icons.map_outlined,
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child:
                            _buildField(
                          controller:
                              _cityController,
                          label:
                              'City',
                          hint:
                              'City',
                          icon:
                              Icons
                                  .location_city_outlined,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            _buildField(
                          controller:
                              _stateController,
                          label:
                              'State',
                          hint:
                              'State',
                          icon:
                              Icons.map_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 13,
                  ),

                  _buildField(
                    controller:
                        _pinCodeController,
                    label:
                        'PIN Code',
                    hint:
                        '6-digit PIN code',
                    icon:
                        Icons.pin_drop_outlined,
                    keyboardType:
                        TextInputType.number,
                    maxLength: 6,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height: 54,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          _saving
                              ? null
                              : _saveAddress,
                      icon: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .check_circle_outline,
                            ),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : 'Save Address',
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            AppColors.primary,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // =========================================================
  // BOOKING HEADER
  // =========================================================

  Widget _buildBookingHeader() {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            AppColors.primary,
            Color(0xFFFF7A33),
          ],
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.primary.withValues(
              alpha: .20,
            ),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withValues(
                alpha: .18,
              ),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color:
                  Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Where should we walk?',
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  'Choose a saved address or use your current location.',
                  style: TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CURRENT LOCATION CARD
  // =========================================================

  Widget _buildCurrentLocationCard() {
    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            _gettingLocation ||
                    _saving
                ? null
                : _useCurrentLocation,
        borderRadius:
            BorderRadius.circular(20),
        child: Ink(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(17),
          decoration:
              BoxDecoration(
            color:
                AppColors.card,
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color: AppColors.primary
                  .withValues(
                alpha: .18,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: .035,
                ),
                blurRadius: 12,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(
                  color: AppColors.primary
                      .withValues(
                    alpha: .10,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    _gettingLocation
                        ? const Padding(
                            padding:
                                EdgeInsets.all(
                              14,
                            ),
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                              color:
                                  AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons
                                .my_location_rounded,
                            color:
                                AppColors.primary,
                            size: 25,
                          ),
              ),
              const SizedBox(
                width: 13,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use Current Location',
                      style: TextStyle(
                        color:
                            AppColors.navy,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Automatically detect your address',
                      style: TextStyle(
                        color:
                            AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .arrow_forward_ios_rounded,
                color:
                    AppColors.slate,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  Widget _buildSectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              const TextStyle(
            color:
                AppColors.navy,
            fontSize: 19,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: AppColors.slate
                .withValues(
              alpha: .75,
            ),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // INPUT FIELD
  // =========================================================

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool requiredField = true,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(
            left: 3,
            bottom: 7,
          ),
          child: Row(
            children: [
              Text(
                label,
                style:
                    const TextStyle(
                  color:
                      AppColors.navy,
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              if (requiredField)
                const Text(
                  ' *',
                  style:
                      TextStyle(
                    color:
                        AppColors.primary,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        TextField(
          controller:
              controller,
          maxLines:
              maxLines,
          maxLength:
              maxLength,
          keyboardType:
              keyboardType,
          textCapitalization:
              TextCapitalization.sentences,
          style:
              const TextStyle(
            color:
                AppColors.navy,
            fontSize: 14,
            fontWeight:
                FontWeight.w600,
          ),
          decoration:
              InputDecoration(
            hintText:
                hint,
            hintStyle:
                TextStyle(
              color: AppColors.slate
                  .withValues(
                alpha: .50,
              ),
              fontSize: 13,
            ),
            counterText:
                maxLength != null
                    ? ''
                    : null,
            prefixIcon:
                Padding(
              padding:
                  const EdgeInsets
                      .only(
                left: 14,
                right: 10,
              ),
              child: Icon(
                icon,
                color:
                    AppColors.primary,
                size: 21,
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(
              minWidth: 48,
            ),
            filled: true,
            fillColor:
                AppColors.card,
            contentPadding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
              borderSide:
                  BorderSide.none,
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
              borderSide:
                  BorderSide(
                color:
                    Colors.black.withValues(
                  alpha: .05,
                ),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                15,
              ),
              borderSide:
                  const BorderSide(
                color:
                    AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SAVED ADDRESS CARD
  // =========================================================

  Widget _buildSavedAddressCard(
    int index,
    Map<String, dynamic> address,
  ) {
    final String title =
        address['title']?.toString() ??
            'Address ${index + 1}';

    final String fullAddress =
        address['address']?.toString() ??
            '';

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap: () =>
            _selectAddress(address),
        borderRadius:
            BorderRadius.circular(19),
        child: Ink(
          width:
              double.infinity,
          padding:
              const EdgeInsets.all(15),
          decoration:
              BoxDecoration(
            color:
                AppColors.card,
            borderRadius:
                BorderRadius.circular(
              19,
            ),
            border:
                Border.all(
              color: AppColors.primary
                  .withValues(
                alpha: .10,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: .035,
                ),
                blurRadius: 12,
                offset:
                    const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                    BoxDecoration(
                  color: AppColors.primary
                      .withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons
                      .location_on_rounded,
                  color:
                      AppColors.primary,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style:
                                const TextStyle(
                              color:
                                  AppColors.navy,
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withValues(
                              alpha: .08,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child:
                              const Text(
                            'SELECT',
                            style:
                                TextStyle(
                              color:
                                  AppColors.primary,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      fullAddress,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AppColors.slate,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        _smallAction(
                          icon:
                              Icons.edit_outlined,
                          label:
                              'Edit',
                          onTap: () =>
                              _editAddress(
                            address,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        _smallAction(
                          icon:
                              Icons.delete_outline,
                          label:
                              'Delete',
                          danger: true,
                          onTap: () =>
                              _deleteAddress(
                            index,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SMALL ACTION
  // =========================================================

  Widget _smallAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final Color color =
        danger
            ? Colors.red
            : AppColors.navy;

    return InkWell(
      onTap:
          onTap,
      borderRadius:
          BorderRadius.circular(10),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 5,
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  color,
            ),
            const SizedBox(
              width: 4,
            ),
            Text(
              label,
              style:
                  TextStyle(
                color:
                    color,
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
