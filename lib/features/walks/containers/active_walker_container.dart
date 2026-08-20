import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkerContainer extends StatelessWidget {
  const ActiveWalkerContainer({
    super.key,
  });

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color border = Color(0xFFD6DAE0);

  static const Color primary = AppColors.primary;
  static const Color callColor = Color(0xFF16A34A);
  static const Color smsColor = Color(0xFF238EAE);

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('active_walk')
          .where(
            'status',
            isEqualTo: 'active',
          )
          .limit(1)
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return _loading();
        }

        if (snapshot.hasError) {
          return _error(
            'Unable to load active walker.',
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeWalk =
            snapshot.data!.docs.first.data();

        final walkerId =
            _stringValue(
          activeWalk['walkerId'],
        );

        if (walkerId.isEmpty) {
          return _error(
            'Walker ID is missing.',
          );
        }

        return FutureBuilder<
            DocumentSnapshot<Map<String, dynamic>>>(
          future: _findWalker(walkerId),
          builder: (
            context,
            walkerSnapshot,
          ) {
            if (walkerSnapshot.connectionState ==
                ConnectionState.waiting) {
              return _loading();
            }

            if (walkerSnapshot.hasError) {
              return _error(
                'Unable to load walker details.',
              );
            }

            final walkerData =
                walkerSnapshot.data?.data() ?? {};

            return _buildCard(
              context,
              activeWalk,
              walkerData,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // FIND WALKER
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      _findWalker(
    String walkerId,
  ) async {
    final directDoc = await _firestore
        .collection('walkers')
        .doc(walkerId)
        .get();

    if (directDoc.exists) {
      return directDoc;
    }

    final query = await _firestore
        .collection('walkers')
        .where(
          'walkerId',
          isEqualTo: walkerId,
        )
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    return directDoc;
  }

  // ==========================================================
  // ACTIVE WALKER CARD
  // ==========================================================

  Widget _buildCard(
    BuildContext context,
    Map<String, dynamic> activeWalk,
    Map<String, dynamic> walkerData,
  ) {
    final walkerId =
        _stringValue(activeWalk['walkerId']);

    final walkerName =
        _walkerName(walkerData);

    final profileImage =
        _profileImage(walkerData);

    final phone =
        _walkerPhone(walkerData);

    return GestureDetector(
      onTap: () {
        _showWalkerDetails(
          context,
          activeWalk,
          walkerData,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: primary.withOpacity(.22),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(.04),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _profileAvatar(
                  profileImage,
                  55,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WALKER ON THE WAY',
                        style: TextStyle(
                          color: primary,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        walkerName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Walker ID: $walkerId',
                        style: const TextStyle(
                          color: slate,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFEAF7EF),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: callColor,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: callColor,
                    onTap: () {
                      _callWalker(phone);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _actionButton(
                    icon: Icons.sms_rounded,
                    label: 'SMS',
                    color: smsColor,
                    onTap: () {
                      _smsWalker(phone);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _actionButton(
                    icon:
                        Icons.location_on_rounded,
                    label: 'Track',
                    color: primary,
                    onTap: () {
                      _showTrackingMessage(
                        context,
                        activeWalk,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: slate,
                  size: 17,
                ),
                SizedBox(width: 3),
                Text(
                  'Tap for walker details',
                  style: TextStyle(
                    color: slate,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PROFILE AVATAR
  // ==========================================================

  Widget _profileAvatar(
    String imageUrl,
    double size,
  ) {
    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _profileIcon(size);
          },
        ),
      );
    }

    return _profileIcon(size);
  }

  Widget _profileIcon(
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withOpacity(.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: primary,
        size: size * .52,
      ),
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 16,
          color: color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              color.withOpacity(.055),
          side: BorderSide(
            color: color.withOpacity(.18),
          ),
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  Widget _loading() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Checking active walker...',
            style: TextStyle(
              color: slate,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _error(
    String message,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: slate,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTTOM SHEET PLACEHOLDER
  // ==========================================================

  void _showWalkerDetails(
    BuildContext context,
    Map<String, dynamic> activeWalk,
    Map<String, dynamic> walkerData,
  ) {
    // Part 3 will provide the complete
    // bottom sheet implementation.
  }

  // ==========================================================
  // CALL
  // ==========================================================

  Future<void> _callWalker(
    String phone,
  ) async {
    if (phone.isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // SMS
  // ==========================================================

  Future<void> _smsWalker(
    String phone,
  ) async {
    if (phone.isEmpty) {
      return;
    }

    final uri = Uri(
      scheme: 'sms',
      path: phone,
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // TRACK
  // ==========================================================

  void _showTrackingMessage(
    BuildContext context,
    Map<String, dynamic> activeWalk,
  ) {
    final lat =
        _doubleValue(
      activeWalk['currentLat'],
    );

    final lng =
        _doubleValue(
      activeWalk['currentLng'],
    );

    final String message;

    if (lat != null && lng != null) {
      message =
          'Walker location: '
          '${lat.toStringAsFixed(5)}, '
          '${lng.toStringAsFixed(5)}';
    } else {
      message =
          'Walker location is not available yet.';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ==========================================================
  // WALKER NAME
  // ==========================================================

  String _walkerName(
    Map<String, dynamic> data,
  ) {
    return _firstString(
      data,
      [
        'Full Name',
        'fullName',
        'name',
        'walkerName',
      ],
      fallback: 'Walker',
    );
  }

  // ==========================================================
  // PHONE
  // ==========================================================

  String _walkerPhone(
    Map<String, dynamic> data,
  ) {
    return _firstString(
      data,
      [
        'Mobile number',
        'mobileNumber',
        'phone',
        'phoneNumber',
        'mobile',
      ],
    );
  }

  // ==========================================================
  // PROFILE IMAGE
  // ==========================================================

  String _profileImage(
    Map<String, dynamic> data,
  ) {
    return _firstString(
      data,
      [
        'Profile Selfie',
        'profileSelfie',
        'profileImage',
        'profileImageUrl',
        'photoUrl',
      ],
    );
  }

  // ==========================================================
  // STRING HELPERS
  // ==========================================================

  String _firstString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];

      if (value is String &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  double? _doubleValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }
}
