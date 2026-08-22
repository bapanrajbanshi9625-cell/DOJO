// File location: lib/screens/main_navigation_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/home/services/home_live_walk_service.dart';
import '../features/home/widgets/home_live_walk_bar.dart';
import '../features/walks/walks_screen.dart';
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
        final String result = value.toString().trim();

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return '';
  }

  // ==========================================================
  // OPEN LIVE WALK
  // ==========================================================

  void _openLiveWalk(
    Map<String, dynamic> data,
  ) {
    if (!mounted) return;

    final String walkId = _readString(
      data,
      const [
        'walkId',
        'walkID',
        'id',
      ],
    );

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

    if (walkId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Live Walk information is not ready yet.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
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
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          if (snapshot.hasData && !snapshot.hasError) {
            liveWalkData =
                _liveWalkService.getLiveWalkData(
              snapshot.data!,
            );
          }

          final bool isActive =
              liveWalkData != null;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // ACTIVE LIVE WALK BAR
              // ONLY VISIBLE WHEN ACTIVE
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
                selectedItemColor: AppColors.primary,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                onTap: _onNavigationTap,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(
                      Icons.directions_walk_rounded,
                    ),
                    label: 'Walks',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu),
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
