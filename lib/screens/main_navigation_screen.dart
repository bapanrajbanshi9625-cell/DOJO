// File location: lib/screens/main_navigation_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/home/services/home_live_walk_service.dart';
import '../features/home/widgets/home_live_walk_bar.dart';
import 'home_screen.dart';
import 'live_walk_screen.dart';
import 'menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {
  // ==========================================================
  // CURRENT SCREEN
  // ==========================================================

  int _currentIndex = 0;

  // ==========================================================
  // LIVE WALK SERVICE
  // ==========================================================

  final HomeLiveWalkService _liveWalkService =
      HomeLiveWalkService.instance;

  // ==========================================================
  // AUTO OPEN CONTROL
  // ==========================================================
  //
  // एक ही active walk के लिए LiveWalkScreen बार-बार
  // automatically open नहीं होगा.
  //
  // Walk बदलने पर नया walk automatically open होगा.
  // ==========================================================

  String? _autoOpenedWalkId;

  bool _isOpeningLiveWalk = false;

  // ==========================================================
  // SCREENS
  // ==========================================================

  final List<Widget> _screens = const [
    HomeScreen(),
    WalksScreen(),
    MenuScreen(),
  ];

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void _onNavigationTap(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // ==========================================================
  // STRING READER
  // ==========================================================

  String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value != null) {
        final String result =
            value.toString().trim();

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return '';
  }

  // ==========================================================
  // GET WALK ID
  // ==========================================================

  String _getWalkId(
    Map<String, dynamic> data,
  ) {
    final String walkId = _readString(
      data,
      const [
        'walkId',
        'walkID',
        'id',
        '_documentId',
      ],
    );

    return walkId;
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  Future<void> _openLiveWalk(
    Map<String, dynamic> data, {
    bool automatic = false,
  }) async {
    if (!mounted) {
      return;
    }

    if (_isOpeningLiveWalk) {
      return;
    }

    final String walkId = _getWalkId(data);

    if (walkId.isEmpty) {
      return;
    }

    final String walkerUid = _readString(
      data,
      const [
        'walkerUid',
        'walkerUID',
        'walkerId',
      ],
    );

    final String walkerName = _readString(
      data,
      const [
        'walkerName',
        'name',
      ],
    );

    final String walkerPhone = _readString(
      data,
      const [
        'walkerPhone',
        'phone',
        'phoneNumber',
      ],
    );

    // ----------------------------------------------------------
    // Mark BEFORE navigation.
    //
    // इससे Firestore stream update के कारण page दोबारा
    // automatically open नहीं होगा.
    // ----------------------------------------------------------

    if (automatic) {
      _autoOpenedWalkId = walkId;
    }

    _isOpeningLiveWalk = true;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveWalkScreen(
            walkId: walkId,
            walkerUid: walkerUid,
            walkerName: walkerName.isEmpty
                ? 'Walker'
                : walkerName,
            walkerPhone: walkerPhone.isEmpty
                ? null
                : walkerPhone,
          ),
        ),
      );
    } finally {
      _isOpeningLiveWalk = false;
    }
  }

  // ==========================================================
  // HANDLE ACTIVE WALK
  // ==========================================================

  void _handleActiveWalk(
    Map<String, dynamic>? liveWalkData,
  ) {
    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // NO ACTIVE WALK
    // ----------------------------------------------------------

    if (liveWalkData == null) {
      // पुरानी walk खत्म हो गई।
      //
      // अगली नई active walk को automatically खोलने की
      // अनुमति रहेगी.
      _autoOpenedWalkId = null;

      return;
    }

    final String walkId =
        _getWalkId(liveWalkData);

    if (walkId.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // ALREADY OPENED
    // ----------------------------------------------------------

    if (_autoOpenedWalkId == walkId) {
      return;
    }

    // ----------------------------------------------------------
    // AUTOMATICALLY OPEN
    // ----------------------------------------------------------

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        if (_isOpeningLiveWalk) {
          return;
        }

        // Double-check because Firestore stream may have
        // changed between frames.
        if (_autoOpenedWalkId == walkId) {
          return;
        }

        _openLiveWalk(
          liveWalkData,
          automatic: true,
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // CURRENT SCREEN
      // ========================================================

      body: _screens[_currentIndex],

      // ========================================================
      // BOTTOM AREA
      // ========================================================

      bottomNavigationBar: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _liveWalkService.liveWalkStream(),

        builder: (context, snapshot) {
          Map<String, dynamic>? liveWalkData;

          if (snapshot.hasData &&
              !snapshot.hasError) {
            liveWalkData =
                _liveWalkService.getLiveWalkData(
              snapshot.data!,
            );
          }

          final bool isActive =
              liveWalkData != null;

          // ----------------------------------------------------
          // AUTOMATIC OPEN
          // ----------------------------------------------------

          if (isActive) {
            _handleActiveWalk(
              liveWalkData,
            );
          } else if (_autoOpenedWalkId != null) {
            // --------------------------------------------------
            // Active walk no longer exists.
            // --------------------------------------------------

            WidgetsBinding.instance
                .addPostFrameCallback(
              (_) {
                if (!mounted) {
                  return;
                }

                _autoOpenedWalkId = null;
              },
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // ACTIVE / LIVE WALK BAR
              //
              // सिर्फ Owner की active walk होने पर दिखाई देगा.
              // ==================================================

              if (isActive)
                HomeLiveWalkBar(
                  onTap: () {
                    _openLiveWalk(
                      liveWalkData!,
                    );
                  },
                ),

              // ==================================================
              // BOTTOM NAVIGATION
              // ==================================================

              BottomNavigationBar(
                currentIndex: _currentIndex,
                selectedItemColor:
                    AppColors.primary,
                unselectedItemColor:
                    Colors.grey,
                type:
                    BottomNavigationBarType.fixed,
                onTap:
                    _onNavigationTap,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.home,
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.directions_walk_rounded,
                    ),
                    label: 'Walks',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.menu,
                    ),
                    label: 'Menu',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
