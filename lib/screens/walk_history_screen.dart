import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class WalkHistoryScreen extends StatelessWidget {
  const WalkHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Walk History', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.pets, color: Colors.white),
              ),
              title: Text('Walk Session #${105 - index}'),
              subtitle: const Text('Distance: 3.2 km • Duration: 45 mins'),
              trailing: const Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
