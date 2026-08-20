import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/active_walk.dart';
import '../models/active_walk_mapper.dart';
import '../services/active_walk_service.dart';

class ActiveWalkerContainer extends StatelessWidget {
  ActiveWalkerContainer({
    super.key,
  });

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color border = Color(0xFFD6DAE0);
  static const Color primary = AppColors.primary;
  static const Color callColor = Color(0xFF16A34A);
  static const Color smsColor = Color(0xFF238EAE);

  // ==========================================================
  // SERVICE
  // ==========================================================

  final ActiveWalkService _service =
      ActiveWalkService.instance;

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    // ========================================================
    // AUTH UID → OWNER PROFILE → OWNER ID
    // ========================================================

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ownerProfiles')
          .doc(user.uid)
          .snapshots(),
      builder: (context, ownerSnapshot) {
        if (ownerSnapshot.connectionState ==
            ConnectionState.waiting) {
          return _loading();
        }

        if (ownerSnapshot.hasError) {
          return _error(
            'Unable to load owner profile.',
          );
        }

        final Map<String, dynamic>? ownerData =
            ownerSnapshot.data?.data();

        if (ownerData == null) {
          return const SizedBox.shrink();
        }

        final String ownerId =
            ownerData['ownerId']
                    ?.toString()
                    .trim() ??
                '';

        if (ownerId.isEmpty) {
          return const SizedBox.shrink();
        }

        // ======================================================
        // OWNER ID → ACTIVE WALK
        // ======================================================

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.watchActiveWalks(
            ownerId: ownerId,
          ),
          builder: (context, snapshot) {
            // ==================================================
            // LOADING
            // ==================================================

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return _loading();
            }

            // ==================================================
            // ERROR
            // ==================================================

            if (snapshot.hasError) {
              return _error(
                'Unable to load active walker.',
              );
            }

            // ==================================================
            // NO ACTIVE WALK
            // ==================================================

            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            // ==================================================
            // FIRST ACTIVE WALK
            // ==================================================

            final QueryDocumentSnapshot<
                    Map<String, dynamic>>
                document =
                snapshot.data!.docs.first;

            final ActiveWalk activeWalk =
                ActiveWalkMapper.fromMap(
              document.id,
              document.data(),
            );

            // ==================================================
            // WALKER ID CHECK
            // ==================================================

            if (activeWalk.walkerId.isEmpty) {
              return _error(
                'Walker ID is missing.',
              );
            }

            // ==================================================
            // CARD
            // ==================================================

            return _buildCard(
              context,
              activeWalk,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // ACTIVE WALKER CARD
  // ==========================================================

  Widget _buildCard(
    BuildContext context,
    ActiveWalk activeWalk,
  ) {
    return GestureDetector(
      onTap: () {
        _showWalkerDetails(
          context,
          activeWalk,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary.withOpacity(.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _profileIcon(55),
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
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activeWalk.walkerName.isNotEmpty
                            ? activeWalk.walkerName
                            : 'Walker',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Walker ID: ${activeWalk.walkerId}',
                        style: const TextStyle(
                          color: slate,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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
                    color: const Color(0xFFEAF7EF),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: callColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
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
                      _callWalker(
                        activeWalk.walkerPhone,
                      );
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
                      _smsWalker(
                        activeWalk.walkerPhone,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: Icons.location_on_rounded,
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
                    fontWeight: FontWeight.w600,
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
  // PROFILE ICON
  // ==========================================================

  Widget _profileIcon(double size) {
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
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              color.withOpacity(.055),
          side: BorderSide(
            color: color.withOpacity(.18),
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Checking active walker...',
            style: TextStyle(
              color: slate,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _error(String message) {
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
  // BOTTOM SHEET
  // ==========================================================

  void _showWalkerDetails(
    BuildContext context,
    ActiveWalk activeWalk,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(27),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4D8DC),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _profileIcon(64),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Walker on the way',
                              style: TextStyle(
                                color: primary,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              activeWalk.walkerName.isNotEmpty
                                  ? activeWalk.walkerName
                                  : 'Walker',
                              style: const TextStyle(
                                color: navy,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Walker ID: ${activeWalk.walkerId}',
                              style: const TextStyle(
                                color: slate,
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8F9),
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: border,
                      ),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          Icons.pets_rounded,
                          'Pet',
                          activeWalk.petName.isNotEmpty
                              ? activeWalk.petName
                              : 'Not available',
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          Icons.badge_outlined,
                          'Walker ID',
                          activeWalk.walkerId,
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          Icons.directions_walk_rounded,
                          'Status',
                          'Walker on the way',
                          valueColor: callColor,
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          Icons.route_rounded,
                          'Distance',
                          activeWalk.distance.isNotEmpty
                              ? activeWalk.distance
                              : 'Not available',
                        ),
                        const Divider(height: 20),
                        _detailRow(
                          Icons.timer_outlined,
                          'Duration',
                          activeWalk.duration.isNotEmpty
                              ? activeWalk.duration
                              : 'Not started',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showTrackingMessage(
                          context,
                          activeWalk,
                        );
                      },
                      icon: const Icon(
                        Icons.location_on_rounded,
                      ),
                      label: const Text(
                        'Track Walker',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Walker is on the way. The live walk has not started yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: slate,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value, {
    Color valueColor = navy,
  }) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: primary.withOpacity(.08),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: slate,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // CALL
  // ==========================================================

  Future<void> _callWalker(
    String phone,
  ) async {
    if (phone.trim().isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone.trim(),
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // SMS
  // ==========================================================

  Future<void> _smsWalker(
    String phone,
  ) async {
    if (phone.trim().isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'sms',
      path: phone.trim(),
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // TRACK
  // ==========================================================

  void _showTrackingMessage(
    BuildContext context,
    ActiveWalk activeWalk,
  ) {
    final double? lat =
        activeWalk.currentLat;

    final double? lng =
        activeWalk.currentLng;

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
}
