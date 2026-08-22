Updated "lib/screens/main_navigation_screen.dart"

// File location: lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
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
  // SCREENS
  // ==========================================================
  //
  // Insta Walk has been completely removed from
  // MainNavigationScreen.
  //
  // ==========================================================

  final List<Widget> _screens = const [
    HomeScreen(),
    WalksScreen(),
    MenuScreen(),
  ];

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
      // MAIN NAVIGATION BAR
      // ========================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        selectedItemColor: AppColors.primary,

        unselectedItemColor: Colors.grey,

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
    );
  }
}
