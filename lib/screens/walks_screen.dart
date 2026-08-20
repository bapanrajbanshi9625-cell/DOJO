import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import 'custom_app_bar.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  // ==========================================================
  // OWNER ROLE COLORS
  // ==========================================================

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color background = Color(0xFFEDEFF2);
  static const Color border = Color(0xFFD6DAE0);
  static const Color green = Color(0xFF16A34A);
  static const Color blue = Color(0xFF238EAE);

  // ==========================================================
  // DEMO WALKER DATA
  // ==========================================================

  static const String walkerName = 'Rahul Kumar';
  static const String walkerId = 'DW-10245';
  static const String walkerGender = 'Male';

  // Phone is used internally only.
  // It is NOT displayed in the UI.
  static const String walkerPhone = '+919876543210';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const CustomAppBar(),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          15,
          18,
          15,
          110,
        ),
        children: [
          // ======================================================
          // PAGE TITLE
          // ======================================================

          Row(
            children: [
              Container(
                height: 21,
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Walks',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Find and manage your dog walks.',
            style: TextStyle(
              color: slate,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // INSTA WALK
          // ======================================================

          _instaWalkCard(),

          const SizedBox(height: 14),

          // ======================================================
          // ACTIVE WALKER
          // ======================================================

          _activeWalkerCard(context),
        ],
      ),
    );
  }

  // ==========================================================
  // INSTA WALK CARD
  // ==========================================================

  Widget _instaWalkCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'Find a Walker',
            style: TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Start a walk request and find an available walker nearby.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: slate,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // Existing Insta Walk logic will be connected here.
              },
              icon: const Icon(
                Icons.search_rounded,
              ),
              label: const Text(
                'Find a Walker',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIVE WALKER CARD
  // ==========================================================

  Widget _activeWalkerCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showWalkerBottomSheet(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(.22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // PROFILE
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 29,
                  ),
                ),

                const SizedBox(width: 12),

                // NAME + ID
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WALKER ON THE WAY',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        walkerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Walker ID: $walkerId',
                        style: TextStyle(
                          color: slate,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // ACTIVE STATUS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: green,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ==================================================
            // CALL / SMS / TRACK
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.call_rounded,
                    label: 'Call',
                    color: green,
                    onTap: _callWalker,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _actionButton(
                    icon: Icons.sms_rounded,
                    label: 'SMS',
                    color: blue,
                    onTap: _smsWalker,
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _actionButton(
                    icon: Icons.location_on_rounded,
                    label: 'Track',
                    color: AppColors.primary,
                    onTap: () {
                      _showTrackingMessage(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
  // CARD ACTION BUTTON
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
          backgroundColor: color.withOpacity(.055),
          side: BorderSide(
            color: color.withOpacity(.18),
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // WALKER BOTTOM SHEET
  // ==========================================================

  void _showWalkerBottomSheet(BuildContext context) {
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
            child: SingleChildScrollView(
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
                    // HANDLE
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4D8DC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // HEADER
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withOpacity(.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 34,
                          ),
                        ),

                        const SizedBox(width: 13),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Walker on the way',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                walkerName,
                                style: TextStyle(
                                  color: navy,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Walker ID: $walkerId',
                                style: TextStyle(
                                  color: slate,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // DETAILS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: border,
                        ),
                      ),
                      child: Column(
                        children: [
                          _detailRow(
                            Icons.person_outline_rounded,
                            'Walker Name',
                            walkerName,
                          ),

                          const Divider(height: 20),

                          _detailRow(
                            Icons.badge_outlined,
                            'Walker ID',
                            walkerId,
                          ),

                          const Divider(height: 20),

                          _detailRow(
                            Icons.wc_rounded,
                            'Gender',
                            walkerGender,
                          ),

                          const Divider(height: 20),

                          _detailRow(
                            Icons.directions_walk_rounded,
                            'Status',
                            'Walker on the way',
                            valueColor: green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // CALL / SMS / TRACK
                    Row(
                      children: [
                        Expanded(
                          child: _bottomAction(
                            icon: Icons.call_rounded,
                            label: 'Call',
                            color: green,
                            onTap: _callWalker,
                          ),
                        ),

                        const SizedBox(width: 9),

                        Expanded(
                          child: _bottomAction(
                            icon: Icons.sms_rounded,
                            label: 'SMS',
                            color: blue,
                            onTap: _smsWalker,
                          ),
                        ),

                        const SizedBox(width: 9),

                        Expanded(
                          child: _bottomAction(
                            icon: Icons.location_on_rounded,
                            label: 'Track',
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _showTrackingMessage(context);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Walker has not started the walk yet.',
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
            color: AppColors.primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
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
            textAlign: TextAlign.end,
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
  // BOTTOM ACTION
  // ==========================================================

  Widget _bottomAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,

        // ROLE COLOR ONLY FOR ICON
        icon: Icon(
          icon,
          size: 17,
          color: color,
        ),

        label: Text(
          label,
          style: const TextStyle(
            color: navy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: navy,
          elevation: 0,
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: color.withOpacity(.18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CALL WALKER
  // ==========================================================

  Future<void> _callWalker() async {
    final Uri uri = Uri(
      scheme: 'tel',
      path: walkerPhone,
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // SMS WALKER
  // ==========================================================

  Future<void> _smsWalker() async {
    final Uri uri = Uri(
      scheme: 'sms',
      path: walkerPhone,
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // TRACK
  // ==========================================================

  void _showTrackingMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Walker tracking will be connected here.',
          ),
        ),
      );
  }
}
