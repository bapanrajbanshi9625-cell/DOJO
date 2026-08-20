import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class WalkerBottomSheet {
  WalkerBottomSheet._();

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color border = Color(0xFFD6DAE0);

  static const Color primary = AppColors.primary;
  static const Color callColor = Color(0xFF16A34A);
  static const Color smsColor = Color(0xFF238EAE);

  // ==========================================================
  // SHOW
  // ==========================================================

  static void show({
    required BuildContext context,
    required Map<String, dynamic> activeWalk,
    required Map<String, dynamic> walkerData,
    required VoidCallback onCall,
    required VoidCallback onSms,
    required VoidCallback onTrack,
  }) {
    final walkerId =
        _stringValue(activeWalk['walkerId']);

    final walkerName =
        _walkerName(walkerData);

    final gender =
        _walkerGender(walkerData);

    final profileImage =
        _profileImage(walkerData);

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
                  // =================================================
                  // HANDLE
                  // =================================================

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

                  // =================================================
                  // HEADER
                  // =================================================

                  Row(
                    children: [
                      _avatar(
                        profileImage,
                        64,
                      ),

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
                              walkerName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Walker ID: $walkerId',
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

                  // =================================================
                  // DETAILS
                  // =================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFF7F8F9),
                      borderRadius:
                          BorderRadius.circular(16),
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

                        const Divider(
                          height: 20,
                        ),

                        _detailRow(
                          Icons.badge_outlined,
                          'Walker ID',
                          walkerId,
                        ),

                        const Divider(
                          height: 20,
                        ),

                        _detailRow(
                          Icons.wc_rounded,
                          'Gender',
                          gender,
                        ),

                        const Divider(
                          height: 20,
                        ),

                        _detailRow(
                          Icons.directions_walk_rounded,
                          'Status',
                          'Walker on the way',
                          valueColor: callColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // ACTIONS
                  // =================================================

                  Row(
                    children: [
                      Expanded(
                        child: _actionButton(
                          icon:
                              Icons.call_rounded,
                          label: 'Call',
                          color: callColor,
                          onTap: onCall,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: _actionButton(
                          icon:
                              Icons.sms_rounded,
                          label: 'SMS',
                          color: smsColor,
                          onTap: onSms,
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: _actionButton(
                          icon:
                              Icons.location_on_rounded,
                          label: 'Track',
                          color: primary,
                          onTap: () {
                            Navigator.pop(
                              sheetContext,
                            );

                            onTrack();
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
        );
      },
    );
  }

  // ==========================================================
  // AVATAR
  // ==========================================================

  static Widget _avatar(
    String imageUrl,
    double size,
  ) {
    if (imageUrl.isEmpty) {
      return _defaultAvatar(size);
    }

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
          return _defaultAvatar(size);
        },
      ),
    );
  }

  static Widget _defaultAvatar(
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            primary.withOpacity(.10),
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

  static Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
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
            color:
                color.withOpacity(.18),
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  static Widget _detailRow(
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
            color:
                primary.withOpacity(.08),
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
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // WALKER NAME
  // ==========================================================

  static String _walkerName(
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
  // GENDER
  // ==========================================================

  static String _walkerGender(
    Map<String, dynamic> data,
  ) {
    return _firstString(
      data,
      [
        'Gender',
        'gender',
        'walkerGender',
      ],
      fallback: 'Not available',
    );
  }

  // ==========================================================
  // PROFILE IMAGE
  // ==========================================================

  static String _profileImage(
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
  // STRING HELPER
  // ==========================================================

  static String _firstString(
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

  // ==========================================================
  // GENERIC STRING
  // ==========================================================

  static String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }
}
