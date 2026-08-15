import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  void _message(
    BuildContext context,
    String message,
  ) {
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
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SupportTile(
            icon:
                Icons.chat_bubble_outline,
            title: 'Contact Support',
            subtitle:
                'Talk to Dojo Walk support',
            onTap: () {
              _message(
                context,
                'Contact Support selected.',
              );
            },
          ),

          const SizedBox(height: 10),

          _SupportTile(
            icon:
                Icons.question_answer_outlined,
            title:
                'Frequently Asked Questions',
            subtitle:
                'Find answers to common questions',
            onTap: () {
              _message(
                context,
                'FAQ selected.',
              );
            },
          ),

          const SizedBox(height: 10),

          _SupportTile(
            icon:
                Icons.report_problem_outlined,
            title: 'Report a Problem',
            subtitle:
                'Tell us about a problem',
            onTap: () {
              _message(
                context,
                'Report a Problem selected.',
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
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
