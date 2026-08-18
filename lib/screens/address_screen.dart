import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // =========================================================
  // STATE
  // =========================================================

  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>>?
      _ownerProfileRef;

  // Temporary UI saved addresses.
  //
  // Backend functionality can be connected later.
  final List<Map<String, String>> _savedAddresses = [];

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

    final QuerySnapshot<Map<String, dynamic>>
        query = await _firestore
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

      if (!mounted) {
        return;
      }

      if (ownerRef == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      _ownerProfileRef = ownerRef;

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await ownerRef.get();

      final Map<String, dynamic> data =
          snapshot.data() ?? {};

      // =====================================================
      // EXISTING ADDRESS
      // =====================================================

      String address =
          data['address']?.toString().trim() ?? '';

      if (address.isEmpty) {
        address =
            data['Adress']?.toString().trim() ?? '';
      }

      // =====================================================
      // LOAD SEPARATE FIELDS IF AVAILABLE
      // =====================================================

      _flatController.text =
          data['flatNumber']?.toString() ?? '';

      _addressLine1Controller.text =
          data['addressLine1']?.toString() ?? '';

      _addressLine2Controller.text =
          data['addressLine2']?.toString() ?? '';

      _areaController.text =
          data['area']?.toString() ?? '';

      _cityController.text =
          data['city']?.toString() ?? '';

      _stateController.text =
          data['state']?.toString() ?? '';

      _pinCodeController.text =
          data['pincode']?.toString() ?? '';

      // =====================================================
      // OLD ADDRESS COMPATIBILITY
      // =====================================================

      if (address.isNotEmpty &&
          _addressLine1Controller.text.trim().isEmpty) {
        _addressLine1Controller.text = address;
      }

      // =====================================================
      // ADD EXISTING ADDRESS TO UI
      // =====================================================

      if (address.isNotEmpty) {
        _savedAddresses.clear();

        _savedAddresses.add({
          'title': 'Address 1',
          'address': address,
        });
      }

      setState(() {
        _loading = false;
      });
    } on FirebaseException catch (e) {
      debugPrint(
        'ADDRESS LOAD ERROR: ${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to load address. Please try again.',
      );
    } catch (e) {
      debugPrint(
        'ADDRESS LOAD ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  // =========================================================
  // SAVE ADDRESS
  // =========================================================

  Future<void> _saveAddress() async {
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

    if (pin.length != 6) {
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
      DocumentReference<Map<String, dynamic>>?
          ownerRef = _ownerProfileRef;

      if (ownerRef == null) {
        ownerRef = await _findOwnerProfile();
      }

      if (ownerRef == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _saving = false;
        });

        _showMessage(
          'Owner profile not found. Please complete your owner profile first.',
        );

        return;
      }

      _ownerProfileRef = ownerRef;

      // =====================================================
      // BUILD FULL ADDRESS
      // =====================================================

      final List<String> parts = [];

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

      final String fullAddress =
          parts.join(', ');

      // =====================================================
      // SAVE
      // =====================================================

      await ownerRef.set(
        {
          'authUid': user.uid,

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
        SetOptions(merge: true),
      );

      // Keep users collection synchronized.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'address': fullAddress,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      // =====================================================
      // UI ADDRESS CARD
      // =====================================================

      if (_savedAddresses.isEmpty) {
        _savedAddresses.add({
          'title': 'Address 1',
          'address': fullAddress,
        });
      } else {
        _savedAddresses[0] = {
          'title': 'Address 1',
          'address': fullAddress,
        };
      }

      setState(() {});

      _showMessage(
        'Address saved successfully.',
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      debugPrint(
        'ADDRESS SAVE FIRESTORE ERROR: '
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
            : 'Unable to save address. Please try again.',
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
        'Unable to save address. Please try again.',
      );
    }
  }

  // =========================================================
  // EDIT ADDRESS
  // =========================================================

  void _editAddress(
    Map<String, String> address,
  ) {
    final String fullAddress =
        address['address'] ?? '';

    if (fullAddress.isNotEmpty &&
        _addressLine1Controller.text.isEmpty) {
      _addressLine1Controller.text =
          fullAddress;
    }

    _showMessage(
      'Edit mode enabled. Update the fields above.',
    );
  }

  // =========================================================
  // DELETE ADDRESS
  // =========================================================

  void _deleteAddress(int index) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Address?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to remove this saved address?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  _savedAddresses.removeAt(index);
                });

                _showMessage(
                  'Address removed from the list.',
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // CURRENT LOCATION
  // =========================================================

  void _useCurrentLocation() {
    _showMessage(
      'Current location will be connected later.',
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Addresses',
          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      // =====================================================
      // BODY
      // =====================================================

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
                18,
                16,
                30,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // TOP CARD
                  // =================================================

                  _buildIntroCard(),

                  const SizedBox(
                    height: 24,
                  ),

                  // =================================================
                  // FORM TITLE
                  // =================================================

                  const Text(
                    'Add New Address',
                    style: TextStyle(
                      color:
                          AppColors.navy,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    'Enter your complete walking location.',
                    style: TextStyle(
                      color: AppColors.slate
                          .withOpacity(.8),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // FLAT / HOUSE
                  // =================================================

                  _buildField(
                    controller:
                        _flatController,
                    label:
                        'Flat / House No.',
                    hint:
                        'e.g. Flat 204, House No. 12',
                    icon:
                        Icons.home_outlined,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // ADDRESS LINE 1
                  // =================================================

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
                    height: 14,
                  ),

                  // =================================================
                  // ADDRESS LINE 2
                  // =================================================

                  _buildField(
                    controller:
                        _addressLine2Controller,
                    label:
                        'Address Line 2',
                    hint:
                        'Landmark / Nearby place',
                    icon:
                        Icons.signpost_outlined,
                    requiredField: false,
                    maxLines: 2,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // AREA
                  // =================================================

                  _buildField(
                    controller:
                        _areaController,
                    label:
                        'Area / Locality',
                    hint:
                        'e.g. Jormuil, Rampara',
                    icon:
                        Icons.map_outlined,
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // CITY + STATE
                  // =================================================

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
                              Icons.location_city_outlined,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
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
                              Icons
                                  .map_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // PIN CODE
                  // =================================================

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
                    height: 18,
                  ),

                  // =================================================
                  // CURRENT LOCATION
                  // =================================================

                  SizedBox(
                    width:
                        double.infinity,
                    height: 50,
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _saving
                              ? null
                              : _useCurrentLocation,
                      icon: const Icon(
                        Icons
                            .my_location_rounded,
                        color:
                            AppColors.primary,
                      ),
                      label:
                          const Text(
                        'Use Current Location',
                        style:
                            TextStyle(
                          color:
                              AppColors.navy,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      style:
                          OutlinedButton
                              .styleFrom(
                        side:
                            BorderSide(
                          color: AppColors
                              .primary
                              .withOpacity(
                            .35,
                          ),
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // =================================================
                  // SAVE BUTTON
                  // =================================================

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
                                  .save_rounded,
                            ),
                      label:
                          Text(
                        _saving
                            ? 'Saving Address...'
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

                  // =================================================
                  // SAVED ADDRESSES
                  // =================================================

                  if (_savedAddresses
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 30,
                    ),

                    const Text(
                      'Saved Addresses',
                      style: TextStyle(
                        color:
                            AppColors.navy,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Choose an address for your walks.',
                      style: TextStyle(
                        color: AppColors
                            .slate
                            .withOpacity(.8),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    ...List.generate(
                      _savedAddresses
                          .length,
                      (index) {
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
                  ],
                ],
              ),
            ),
    );
  }

  // =========================================================
  // INTRO CARD
  // =========================================================

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
            color: AppColors.primary
                .withOpacity(.20),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration:
                BoxDecoration(
              color: Colors.white
                  .withOpacity(.18),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons
                  .location_on_rounded,
              color:
                  Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'Walking Address',
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
                  'Save your exact location so walkers can find you easily.',
                  style: TextStyle(
                    color:
                        Colors.white
                            .withOpacity(
                      .88,
                    ),
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
  // INPUT FIELD
  // =========================================================

  Widget _buildField({
    required TextEditingController
        controller,
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
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType:
              keyboardType,
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
            hintText: hint,
            hintStyle:
                TextStyle(
              color: AppColors
                  .slate
                  .withOpacity(
                .55,
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
                  BorderRadius
                      .circular(
                15,
              ),
              borderSide:
                  BorderSide.none,
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius
                      .circular(
                15,
              ),
              borderSide:
                  BorderSide(
                color: Colors.black
                    .withOpacity(
                  .05,
                ),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius
                      .circular(
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
    Map<String, String> address,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            AppColors.card,
        borderRadius:
            BorderRadius.circular(
          18,
        ),
        border:
            Border.all(
          color: AppColors.primary
              .withOpacity(.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(.035),
            blurRadius: 12,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration:
                BoxDecoration(
              color: AppColors
                  .primary
                  .withOpacity(
                .10,
              ),
              borderRadius:
                  BorderRadius
                      .circular(
                13,
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
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  address['title'] ??
                      'Address ${index + 1}',
                  style:
                      const TextStyle(
                    color:
                        AppColors.navy,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Text(
                  address['address'] ??
                      '',
                  style:
                      const TextStyle(
                    color:
                        AppColors.slate,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          // ===================================================
          // THREE DOT MENU
          // ===================================================

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color:
                  AppColors.slate,
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            onSelected:
                (String value) {
              if (value ==
                  'edit') {
                _editAddress(
                  address,
                );
              }

              if (value ==
                  'delete') {
                _deleteAddress(
                  index,
                );
              }
            },
            itemBuilder:
                (BuildContext context) {
              return const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .edit_outlined,
                        size: 19,
                        color:
                            AppColors.navy,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Edit',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .delete_outline,
                        size: 19,
                        color:
                            Colors.red,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Delete',
                        style:
                            TextStyle(
                          color:
                              Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}
