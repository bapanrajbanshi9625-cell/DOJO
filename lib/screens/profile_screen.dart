import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/profile/profile_features.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color orange = Color(0xFFF4511E);

  String mobileNumber = '';
  String ownerUid = '';

  String ownerName = 'Owner';
  String ownerAge = '-';
  String ownerGender = '-';
  String memberSince = '-';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerProfile();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadOwnerProfile() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      final String uid = user.uid;

      final String phone =
          user.phoneNumber ?? '';

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

      final Map<String, dynamic>? data =
          snapshot.data();

      final String name =
          data?['name']?.toString() ??
              data?['fullName']?.toString() ??
              'Owner';

      final String age =
          data?['age']?.toString() ?? '-';

      final String gender =
          data?['gender']?.toString() ?? '-';

      String joinedDate = '-';

      final dynamic createdAt =
          data?['createdAt'];

      if (createdAt is Timestamp) {
        final DateTime date =
            createdAt.toDate();

        joinedDate =
            '${_monthName(date.month)} '
            '${date.day}, '
            '${date.year}';
      } else if (data?['memberSince'] != null) {
        joinedDate =
            data!['memberSince'].toString();
      }

      if (!mounted) return;

      setState(() {
        ownerUid = uid;

        mobileNumber =
            _formatIndianNumber(phone);

        ownerName = name;
        ownerAge = age;
        ownerGender = gender;
        memberSince = joinedDate;

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Profile Firebase Error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // FORMAT MOBILE
  // ============================================================

  String _formatIndianNumber(String number) {
    final String clean =
        number.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length >= 10) {
      final String last10 =
          clean.substring(
        clean.length - 10,
      );

      return '+91 '
          '${last10.substring(0, 5)} '
          '${last10.substring(5)}';
    }

    return number.isEmpty ? '-' : number;
  }

  // ============================================================
  // MONTH
  // ============================================================

  String _monthName(int month) {
    const List<String> months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month];
  }

  // ============================================================
  // CHANGE MOBILE
  // ============================================================

  void _openChangeMobile() {
    if (mobileNumber.isEmpty ||
        mobileNumber == '-') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current mobile number is not available.',
          ),
        ),
      );

      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (_) {
        return ChangeMobileFlow(
          currentNumber: mobileNumber,
          onChanged: (String newNumber) {
            setState(() {
              mobileNumber = newNumber;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // COPY UID
  // ============================================================

  Future<void> _copyOwnerUid() async {
    if (ownerUid.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(
        text: ownerUid,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF303030),
        content: Text(
          'Owner UID copied.',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F8F8),

      appBar: AppBar(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 21,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        titleSpacing: 0,

        title: const Row(
          children: [
            Icon(
              Icons.person_rounded,
              size: 27,
            ),
            SizedBox(width: 10),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: orange,
                ),
              )
            : RefreshIndicator(
                color: orange,
                onRefresh: _loadOwnerProfile,

                child: SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

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
                      ProfileCard(
                        ownerName: ownerName,
                      ),

                      const SizedBox(height: 28),

                      const Padding(
                        padding:
                            EdgeInsets.symmetric(
                          horizontal: 4,
                        ),

                        child: Text(
                          'Owner Information',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight:
                                FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      OwnerInformationCard(
                        mobileNumber: mobileNumber,
                        ownerName: ownerName,
                        ownerAge: ownerAge,
                        ownerGender: ownerGender,
                        ownerUid: ownerUid,
                        memberSince: memberSince,
                        onChangeMobile:
                            _openChangeMobile,
                        onCopyUid:
                            _copyOwnerUid,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
