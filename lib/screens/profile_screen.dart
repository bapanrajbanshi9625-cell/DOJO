import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/profile/profile_features.dart';
import '../services/profile_setup_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange =
      Color(0xFFF4511E);

  static const Color navy =
      Color(0xFF263746);

  static const Color background =
      Color(0xFFEDEFF2);

  // ============================================================
  // PROFILE DATA
  // ============================================================

  String mobileNumber = '';

  // BUSINESS ID
  String ownerId = '';

  // BACKEND UID
  String authUid = '';

  String ownerName = 'Owner';
  String ownerAge = '-';
  String ownerGender = '-';
  String memberSince = '-';

  bool isActive = true;
  bool isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadOwnerProfile();
  }

  // ============================================================
  // LOAD OWNER PROFILE
  // ============================================================

  Future<void> _loadOwnerProfile() async {
    try {
      // ========================================================
      // CURRENT FIREBASE USER
      // ========================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // GET OWNER PROFILE
      // ========================================================
      //
      // IMPORTANT:
      //
      // This now reads:
      //
      // ownerProfiles/{ownerId}
      //
      // NOT:
      //
      // users/{uid}
      //
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await ProfileSetupService
              .getCurrentOwnerProfile();

      if (!snapshot.exists) {
        if (!mounted) return;

        setState(() {
          authUid = user.uid;

          mobileNumber =
              _formatIndianNumber(
            user.phoneNumber ?? '',
          );

          isLoading = false;
        });

        return;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      // ========================================================
      // OWNER ID
      // ========================================================

      final String loadedOwnerId =
          data?['ownerId']?.toString() ??
              snapshot.id;

      // ========================================================
      // AUTH UID
      // ========================================================

      final String loadedAuthUid =
          data?['authUid']?.toString() ??
              user.uid;

      // ========================================================
      // PHONE
      // ========================================================

      final String phone =
          data?['phone']?.toString() ??
              user.phoneNumber ??
              '';

      // ========================================================
      // FULL NAME
      // ========================================================

      final String name =
          data?['fullName']?.toString() ??
              'Owner';

      // ========================================================
      // AGE
      // ========================================================

      final String age =
          data?['age']?.toString() ??
              '-';

      // ========================================================
      // GENDER
      // ========================================================

      final String gender =
          data?['gender']?.toString() ??
              '-';

      // ========================================================
      // ACTIVE STATUS
      // ========================================================

      final bool active =
          data?['isActive'] == true;

      // ========================================================
      // MEMBER SINCE
      // ========================================================

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
      }

      // ========================================================
      // UPDATE UI
      // ========================================================

      if (!mounted) return;

      setState(() {
        ownerId = loadedOwnerId;

        authUid = loadedAuthUid;

        mobileNumber =
            _formatIndianNumber(phone);

        ownerName = name;

        ownerAge = age;

        ownerGender = gender;

        memberSince = joinedDate;

        isActive = active;

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Owner Profile Firebase Error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load owner profile.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // FORMAT MOBILE NUMBER
  // ============================================================

  String _formatIndianNumber(
    String number,
  ) {
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

    return number.isEmpty
        ? '-'
        : number;
  }

  // ============================================================
  // MONTH NAME
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

    if (month < 1 ||
        month > 12) {
      return '';
    }

    return months[month];
  }

  // ============================================================
  // CHANGE MOBILE
  // ============================================================

  void _openChangeMobile() {
    if (mobileNumber.isEmpty ||
        mobileNumber == '-') {
      ScaffoldMessenger.of(context)
          .showSnackBar(
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
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return ChangeMobileFlow(
          currentNumber: mobileNumber,
          onChanged: (
            String newNumber,
          ) {
            if (!mounted) return;

            setState(() {
              mobileNumber = newNumber;
            });
          },
        );
      },
    );
  }

  // ============================================================
  // COPY OWNER ID
  // ============================================================

  Future<void> _copyOwnerId() async {
    if (ownerId.isEmpty) return;

    await Clipboard.setData(
      ClipboardData(
        text: ownerId,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        backgroundColor:
            Color(0xFF303030),
        content: Text(
          'Owner ID copied.',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 52,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
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
              size: 21,
            ),

            SizedBox(width: 7),

            Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(
                  color: orange,
                  strokeWidth: 2.5,
                ),
              )
            : RefreshIndicator(
                color: orange,
                onRefresh:
                    _loadOwnerProfile,

                child:
                    SingleChildScrollView(
                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    15,
                    12,
                    15,
                    24,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      // ==================================================
                      // PROFILE CARD
                      // ==================================================

                      ProfileCard(
                        ownerName:
                            ownerName,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // OWNER INFORMATION TITLE
                      // ==================================================

                      Row(
                        children: [
                          Container(
                            height: 19,
                            width: 4,
                            decoration:
                                BoxDecoration(
                              color: orange,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                5,
                              ),
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          const Text(
                            'Owner Information',
                            style: TextStyle(
                              color: navy,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==================================================
                      // OWNER INFORMATION CARD
                      // ==================================================

                      OwnerInformationCard(
                        mobileNumber:
                            mobileNumber,

                        ownerName:
                            ownerName,

                        ownerAge:
                            ownerAge,

                        ownerGender:
                            ownerGender,

                        // IMPORTANT:
                        // Owner UID replaced by Owner ID.
                        ownerUid:
                            ownerId,

                        memberSince:
                            memberSince,

                        onChangeMobile:
                            _openChangeMobile,

                        onCopyUid:
                            _copyOwnerId,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==================================================
                      // ACTIVE STATUS
                      // ==================================================

                      _OwnerStatusCard(
                        isActive:
                            isActive,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ============================================================
// OWNER STATUS CARD
// ============================================================

class _OwnerStatusCard
    extends StatelessWidget {
  final bool isActive;

  const _OwnerStatusCard({
    required this.isActive,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : Icons.block_rounded,
            color: isActive
                ? Colors.green
                : Colors.red,
            size: 24,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Status',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(0xFF263746),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  isActive
                      ? 'Active'
                      : 'Inactive',
                  style: TextStyle(
                    color: isActive
                        ? Colors.green
                        : Colors.red,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
