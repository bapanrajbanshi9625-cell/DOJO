import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Walker Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: const [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Rahul Sharma',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'DOJO-WLK-104 • Active Walker',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
