import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/section_title.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController _addressController =
      TextEditingController();

  bool _saved = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final address = data?['address'];

      if (address is String && address.trim().isNotEmpty) {
        if (!mounted) return;

        setState(() {
          _addressController.text = address.trim();
          _saved = true;
        });
      }
    } catch (_) {
      // Keep the screen usable even if loading fails.
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    final address = _addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your address'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        _saved = true;
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save address'),
        ),
      );
    }
  }

  void _useCurrentLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Current location will be connected here.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Address',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Address',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Update the address used for your walks.',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const SectionTitle(
              title: 'ADDRESS',
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _addressController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter your complete address',
                filled: true,
                fillColor: AppColors.card,
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveAddress,
                icon: _saving
                    ? const SizedBox(
                        height: 19,
                        width: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : _saved
                          ? 'Address Saved'
                          : 'Save Address',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _useCurrentLocation,
                icon: const Icon(
                  Icons.my_location,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Use Current Location',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (_saved) ...[
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _addressController.text,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
