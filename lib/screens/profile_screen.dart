import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/profile/profile_features.dart';

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

  static const Color orange = Color(0xFFF4511E);
  static const Color navy = Color(0xFF263746);
  static const Color background = Color(0xFFEDEFF2);

  // ============================================================
  // PROFILE DATA
  // ============================================================

  String ownerId = '';
  String authUid = '';

  String mobileNumber = '';
  String ownerName = 'Owner';
  String memberSince = '-';

  String aadhaarNumber = '';

  bool isActive = true;
  bool isLoading = true;
  bool _showAadhaar = false;

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
      // AUTH UID
      // ========================================================

      final String uid = user.uid;

      // ========================================================
      // STEP 1
      // UID -> phoneAccounts -> OWNER ID
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          phoneAccountSnapshot =
          await FirebaseFirestore.instance
              .collection('phoneAccounts')
              .doc(uid)
              .get();

      final Map<String, dynamic>? phoneAccountData =
          phoneAccountSnapshot.data();

      String foundOwnerId =
          phoneAccountData?['ownerId']?.toString() ?? '';

      // ========================================================
      // FALLBACK
      // ========================================================

      if (foundOwnerId.isEmpty) {
        final String? authPhone =
            user.phoneNumber;

        if (authPhone != null &&
            authPhone.isNotEmpty) {
          final QuerySnapshot<Map<String, dynamic>>
              ownerQuery =
              await FirebaseFirestore.instance
                  .collection('ownerProfiles')
                  .where(
                    'authUid',
                    isEqualTo: uid,
                  )
                  .limit(1)
                  .get();

          if (ownerQuery.docs.isNotEmpty) {
            foundOwnerId =
                ownerQuery.docs.first.id;
          }
        }
      }

      // ========================================================
      // OWNER ID NOT FOUND
      // ========================================================

      if (foundOwnerId.isEmpty) {
        if (!mounted) return;

        setState(() {
          authUid = uid;
          mobileNumber =
              _formatIndianNumber(
            user.phoneNumber ?? '',
          );
          isLoading = false;
        });

        return;
      }

      // ========================================================
      // STEP 2
      // OWNER ID -> ownerProfiles
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>>
          ownerSnapshot =
          await FirebaseFirestore.instance
              .collection('ownerProfiles')
              .doc(foundOwnerId)
              .get();

      if (!ownerSnapshot.exists) {
        if (!mounted) return;

        setState(() {
          ownerId = foundOwnerId;
          authUid = uid;

          mobileNumber =
              _formatIndianNumber(
            user.phoneNumber ?? '',
          );

          isLoading = false;
        });

        return;
      }

      final Map<String, dynamic>? data =
          ownerSnapshot.data();

      // ========================================================
      // NAME
      // ========================================================

      final String name =
          data?['fullName']?.toString() ??
              data?['name']?.toString() ??
              data?['ownerName']?.toString() ??
              'Owner';

      // ========================================================
      // PHONE
      // ========================================================

      final String phone =
          data?['phone']?.toString() ??
              user.phoneNumber ??
              '';

      // ========================================================
      // AADHAAR
      // ========================================================

      final String aadhaar =
          data?['aadhaarNumber']?.toString() ??
              data?['Aadhar Number']?.toString() ??
              data?['aadhaar']?.toString() ??
              '';

      // ========================================================
      // ACTIVE STATUS
      // ========================================================

      final dynamic activeValue =
          data?['isActive'];

      final bool active =
          activeValue is bool
              ? activeValue
              : true;

      // ========================================================
      // CREATED DATE
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
      // UPDATE SCREEN
      // ========================================================

      if (!mounted) return;

      setState(() {
        ownerId = foundOwnerId;
        authUid =
            data?['authUid']?.toString() ?? uid;

        mobileNumber =
            _formatIndianNumber(phone);

        ownerName = name;

        aadhaarNumber = aadhaar;

        isActive = active;

        memberSince = joinedDate;

        isLoading = false;

        // Always hide Aadhaar after loading.
        _showAadhaar = false;
      });
    } catch (e) {
      debugPrint(
        'Owner Profile Firebase Error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // FORMAT INDIAN NUMBER
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

    return months[month];
  }

  // ============================================================
  // MASK AADHAAR
  // ============================================================

  String _maskedAadhaar() {
    if (aadhaarNumber.isEmpty) {
      return 'Not available';
    }

    final String clean =
        aadhaarNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length != 12) {
      return '•••• •••• ••••';
    }

    return '•••• •••• ${clean.substring(8)}';
  }

  // ============================================================
  // DISPLAY AADHAAR
  // ============================================================

  String _displayAadhaar() {
    if (!_showAadhaar) {
      return _maskedAadhaar();
    }

    final String clean =
        aadhaarNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length != 12) {
      return aadhaarNumber.isEmpty
          ? 'Not available'
          : aadhaarNumber;
    }

    return '${clean.substring(0, 4)} '
        '${clean.substring(4, 8)} '
        '${clean.substring(8, 12)}';
  }

  // ============================================================
  // TOGGLE AADHAAR
  // ============================================================

  void _toggleAadhaar() {
    if (aadhaarNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aadhaar number is not available.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _showAadhaar = !_showAadhaar;
    });
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
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return ChangeMobileFlow(
          currentNumber: mobileNumber,
          onChanged: (String newNumber) {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF303030),
        content: Text(
          'Owner ID copied.',
        ),
      ),
    );
  }

  // ============================================================
  // COPY AADHAAR
  // ============================================================

  Future<void> _copyAadhaar() async {
    if (aadhaarNumber.isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: aadhaarNumber,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF303030),
        content: Text(
          'Aadhaar number copied.',
        ),
      ),
    );
  }

  // ============================================================
  // OWNER INFORMATION ITEM
  // ============================================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: orange.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
                      const EdgeInsets.fromLTRB(
                    15,
                    12,
                    15,
                    24,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                                      .circular(5),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          const Text(
                            'Owner Information',
                            style:
                                TextStyle(
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
                      // OWNER INFORMATION
                      // ==================================================

                      Container(
                        padding:
                            const EdgeInsets
                                .all(10),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child: Column(
                          children: [
                            // OWNER ID
                            _infoRow(
                              icon: Icons
                                  .badge_outlined,
                              label:
                                  'Owner ID',
                              value:
                                  ownerId.isEmpty
                                      ? '-'
                                      : ownerId,
                              trailing:
                                  IconButton(
                                icon:
                                    const Icon(
                                  Icons
                                      .content_copy_rounded,
                                  size: 18,
                                  color:
                                      orange,
                                ),
                                onPressed:
                                    _copyOwnerId,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            // FULL NAME
                            _infoRow(
                              icon: Icons
                                  .person_outline_rounded,
                              label:
                                  'Full Name',
                              value:
                                  ownerName,
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            // MOBILE
                            _infoRow(
                              icon: Icons
                                  .phone_outlined,
                              label:
                                  'Mobile Number',
                              value:
                                  mobileNumber,
                              trailing:
                                  IconButton(
                                icon:
                                    const Icon(
                                  Icons
                                      .edit_outlined,
                                  size: 19,
                                  color:
                                      orange,
                                ),
                                onPressed:
                                    _openChangeMobile,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            // AADHAAR
                            _infoRow(
                              icon: Icons
                                  .verified_user_outlined,
                              label:
                                  'Aadhaar Number',
                              value:
                                  _displayAadhaar(),
                              trailing:
                                  Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  IconButton(
                                    tooltip:
                                        _showAadhaar
                                            ? 'Hide Aadhaar'
                                            : 'Show Aadhaar',
                                    icon:
                                        Icon(
                                      _showAadhaar
                                          ? Icons
                                              .visibility_off_outlined
                                          : Icons
                                              .visibility_outlined,
                                      size: 19,
                                      color:
                                          orange,
                                    ),
                                    onPressed:
                                        _toggleAadhaar,
                                  ),
                                  if (_showAadhaar)
                                    IconButton(
                                      tooltip:
                                          'Copy Aadhaar',
                                      icon:
                                          const Icon(
                                        Icons
                                            .content_copy_rounded,
                                        size: 17,
                                        color:
                                            orange,
                                      ),
                                      onPressed:
                                          _copyAadhaar,
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            // ACCOUNT STATUS
                            _infoRow(
                              icon: isActive
                                  ? Icons
                                      .check_circle_outline
                                  : Icons
                                      .block_outlined,
                              label:
                                  'Account Status',
                              value:
                                  isActive
                                      ? 'Active'
                                      : 'Inactive',
                              trailing:
                                  Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      10,
                                  vertical: 5,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: isActive
                                      ? Colors
                                          .green
                                          .withOpacity(
                                          0.10,
                                        )
                                      : Colors
                                          .red
                                          .withOpacity(
                                          0.10,
                                        ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),
                                ),
                                child:
                                    Text(
                                  isActive
                                      ? 'ACTIVE'
                                      : 'INACTIVE',
                                  style:
                                      TextStyle(
                                    color: isActive
                                        ? Colors
                                            .green
                                        : Colors
                                            .red,
                                    fontSize:
                                        10,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            // MEMBER SINCE
                            _infoRow(
                              icon: Icons
                                  .calendar_month_outlined,
                              label:
                                  'Member Since',
                              value:
                                  memberSince,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
