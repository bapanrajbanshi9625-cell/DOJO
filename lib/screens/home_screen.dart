import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const orange = AppColors.primary;
  static const navy = Color(0xFF263746);
  static const slate = Color(0xFF475569);
  static const background = Color(0xFFEDEFF2);
  static const card = Color(0xFFF7F8FA);

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Session QR Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Icon(Icons.qr_code, size: 160, color: AppColors.secondary),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan this QR code to validate walk session for Buddy.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _appBarButton(
    BuildContext context,
    IconData icon,
    String title,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.17),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.30),
        ),
      ),
      child: IconButton(
        tooltip: title,
        icon: Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () {
          if (title == 'Help & Support') {
            _showDialog(context, title, '$title button pressed.');
          } else if (title == 'Profile') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: 21,
          width: 4,
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    String suffix = '',
    required IconData icon,
    required Color iconColor,
    required String details,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        _showDialog(
          context,
          '$title Details',
          details,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFD4D9DF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 37,
              width: 37,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: slate,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (suffix.isNotEmpty)
                    TextSpan(
                      text: suffix,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walkCard(
    BuildContext context, {
    required String id,
    required String time,
    required String date,
    required String distance,
    required String duration,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6DAE0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pets, color: orange, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$date • $time',
                    style: const TextStyle(color: slate, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                distance,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                duration,
                style: const TextStyle(color: slate, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 14,
        title: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
              child: const Icon(
                Icons.pets,
                size: 21,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dojo',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Walk Dashboard',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _appBarButton(
            context,
            Icons.support_agent,
            'Help & Support',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          _appBarButton(
            context,
            Icons.person_outline,
            'Profile',
          ),
          const SizedBox(width: 7),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 18, 15, 110),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // WELCOME HEADER
                  // =================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF34495E),
                          Color(0xFF263746),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: BoxDecoration(
                            color: orange.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: orange.withOpacity(0.45),
                            ),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: orange,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back 👋',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Your walking activity is on track.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =================================================
                  // LIVE MAP VIEW SECTION (New Addition)
                  // =================================================
                  Container(
                    height: 190,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.map, size: 60, color: AppColors.secondary),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Live Map View (GPS Route)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =================================================
                  // CURRENT WEEK
                  // =================================================
                  _sectionTitle('Current Week Processing'),
                  const SizedBox(height: 11),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFD6DAE0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                context,
                                title: 'Total Walks',
                                value: '12',
                                icon: Icons.pets,
                                iconColor: orange,
                                details: 'Completed Walks: 12\n'
                                    'Average Walks/Day: 1.5\n'
                                    'Status: On Track',
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _statCard(
                                context,
                                title: 'Distance',
                                value: '24.5',
                                suffix: ' km',
                                icon: Icons.route,
                                iconColor: const Color(0xFF2196F3),
                                details: 'Total Distance: 24.5 km\n'
                                    'Average per Walk: 2.04 km\n'
                                    'Longest Walk: 3.5 km',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        
                        // Stat row 3 items (from new code)
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Distance', '3.2 km')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard('Duration', '45 min')),
                            const SizedBox(width: 8),
                            Expanded(child: _buildStatCard('Pace', '4 min/km')),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // REPORT CARD
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _showDialog(
                              context,
                              'Report Card',
                              'First Week Report: Completed (10 Walks)\n\n'
                              'Current Week Report: Active (12 Walks)\n\n'
                              'Current Week Start: 03 Aug 2026',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1EA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: orange.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 45,
                                  width: 45,
                                  decoration: BoxDecoration(
                                    color: orange,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.assessment_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Report Card',
                                        style: TextStyle(
                                          color: navy,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Weekly walking performance',
                                        style: TextStyle(
                                          color: slate,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: orange,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'SEE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 23),

                  // =================================================
                  // ACTIVE BUDDY SESSION CARD (From new code)
                  // =================================================
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.secondary,
                          child: Icon(Icons.pets, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Buddy (Dog Walk)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'DOJO-WLK-104 • Active Session',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                          onPressed: () => _showQrDialog(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 23),

                  // =================================================
                  // PAST WALK
                  // =================================================
                  _sectionTitle('Past Walk'),
                  const SizedBox(height: 11),

                  _walkCard(
                    context,
                    id: '#WID-9842',
                    time: '08:30 AM',
                    date: '04 Aug 2026',
                    distance: '2.1 km',
                    duration: '30 mins',
                  ),
                  const SizedBox(height: 9),
                  _walkCard(
                    context,
                    id: '#WID-9817',
                    time: '07:15 AM',
                    date: '03 Aug 2026',
                    distance: '1.8 km',
                    duration: '27 mins',
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // =====================================================
      // QR BUTTON
      // =====================================================
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () {
          _showQrDialog(context);
        },
        icon: const Icon(Icons.qr_code_2),
        label: const Text(
          'Generate QR Code',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
