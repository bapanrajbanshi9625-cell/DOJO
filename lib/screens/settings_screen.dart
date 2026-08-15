import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../widgets/section_title.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool darkMode = false;
  bool location = true;
  bool sounds = true;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(
            title: 'APPEARANCE',
          ),

          const SizedBox(height: 10),

          _SwitchCard(
            icon:
                Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle:
                'Use dark appearance throughout the app',
            value: darkMode,
            onChanged: (value) {
              setState(() {
                darkMode = value;
              });

              _showMessage(
                value
                    ? 'Dark Mode enabled'
                    : 'Dark Mode disabled',
              );
            },
          ),

          const SizedBox(height: 26),

          const SectionTitle(
            title: 'APP SETTINGS',
          ),

          const SizedBox(height: 10),

          _SwitchCard(
            icon:
                Icons.location_on_outlined,
            title: 'Location',
            subtitle:
                'Allow location-based walk features',
            value: location,
            onChanged: (value) {
              setState(() {
                location = value;
              });
            },
          ),

          const SizedBox(height: 10),

          _SwitchCard(
            icon:
                Icons.volume_up_outlined,
            title: 'Sounds',
            subtitle:
                'Enable app sounds',
            value: sounds,
            onChanged: (value) {
              setState(() {
                sounds = value;
              });
            },
          ),

          const SizedBox(height: 10),

          _SettingsTile(
            icon:
                Icons.notifications_outlined,
            title:
                'Notification Settings',
            subtitle:
                'Manage your notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const NotificationsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _SettingsTile(
            icon:
                Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              _showMessage(
                'Language settings selected.',
              );
            },
          ),

          const SizedBox(height: 10),

          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: 'Version 1.0.0',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName:
                    'Dojo Walk',
                applicationVersion:
                    '1.0.0',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.slate,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          activeColor:
              AppColors.primary,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      elevation: 0,
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.slate,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.slate,
        ),
        onTap: onTap,
      ),
    );
  }
}
