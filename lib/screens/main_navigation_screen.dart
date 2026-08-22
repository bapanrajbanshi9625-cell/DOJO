// File location: lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/insta_walk/widgets/insta_walk_container.dart';
import '../features/walks/walks_screen.dart';
import 'home_screen.dart';
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
  // INSTA WALK ACTIVE STATE
  //
  // false = no active Insta Walk
  // true  = searching / accepted / active
  // ==========================================================

  bool _instaWalkActive = false;

  // ==========================================================
  // SCREENS
  // ==========================================================

  final List<Widget> _screens = const [
    HomeScreen(),
    WalksScreen(),
    MenuScreen(),
  ];

  // ==========================================================
  // INSTA WALK STATE CHANGE
  // ==========================================================

  void _onInstaWalkActiveChanged(bool active) {
    if (!mounted) return;

    if (_instaWalkActive == active) {
      return;
    }

    setState(() {
      _instaWalkActive = active;
    });
  }

  // ==========================================================
  // OPEN INSTA WALK
  // ==========================================================

  void _openInstaWalk() {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          backgroundColor: Color(0xFFEDEFF2),
          appBar: AppBar(
            title: Text(
              'Insta Walk',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: InstaWalkContainer(
                fullScreen: true,
              ),
            ),
          ),
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

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================================
          // ACTIVE INSTA WALK BAR
          //
          // ONLY VISIBLE WHEN:
          //
          // Searching
          // OR
          // Walker accepted / active
          // ====================================================

          if (_instaWalkActive)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  6,
                  12,
                  6,
                ),
                child: InstaWalkContainer(
                  fullScreen: false,
                  onTap: _openInstaWalk,
                  onActiveChanged:
                      _onInstaWalkActiveChanged,
                ),
              ),
            ),

          // ====================================================
          // MAIN NAVIGATION BAR
          // ====================================================

          BottomNavigationBar(
            currentIndex: _currentIndex,

            selectedItemColor:
                AppColors.primary,

            unselectedItemColor:
                Colors.grey,

            type: BottomNavigationBarType.fixed,

            onTap: (index) {
              if (_currentIndex == index) {
                return;
              }

              setState(() {
                _currentIndex = index;
              });
            },

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
      ),
    );
  }
}
