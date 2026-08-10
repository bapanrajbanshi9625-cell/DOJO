import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.secondary, child: Icon(Icons.notifications, color: Colors.white)),
            title: Text('Walk Started'),
            subtitle: Text('Your scheduled walk session with Buddy has started successfully.'),
          ),
        ],
      ),
    );
  }
}
