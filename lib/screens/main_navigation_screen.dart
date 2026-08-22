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
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.directions_walk_rounded),
            label: 'Walks',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
      ),
    );
  }
}
