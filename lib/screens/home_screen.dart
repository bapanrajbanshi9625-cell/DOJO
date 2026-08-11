import 'package:flutter/material.dart';
import 'custom_app_bar.dart'; // Import Custom App Bar
import 'generate_qr_screen.dart'; // Generate QR Screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const orange = Color(0xFFF4511E);
  static const navy = Color(0xFF263746);
  static const slate = Color(0xFF475569);
  static const background = Color(0xFFEDEFF2);
  static const card = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // =====================================================
      // APP BAR (Using Custom App Bar from separate file)
      // =====================================================
      appBar: const CustomAppBar(),

      // =====================================================
      // BODY
      // =====================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          15,
          18,
          15,
          110,
        ),
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
            // THIS WEEK PROCESSING (Increased Height & Spacing)
            // =================================================
            _sectionTitle(
              'This week processing',
            ),

            const SizedBox(height: 11),

            Container(
              padding: const EdgeInsets.all(18),
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
                  // -------------------------------------------
                  // ROW 1: TOTAL WALKS & DISTANCE
                  // -------------------------------------------
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
                      const SizedBox(width: 12),
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

                  const SizedBox(height: 12),

                  // -------------------------------------------
                  // ROW 2: ACTIVE DURATION & REPORT CARD
                  // -------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: _durationCard(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _reportCard(context),
                      ),
                    ],
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

      // =====================================================
      // QR BUTTON
      // =====================================================
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 8,

        // ===================================================
        // ONLY UPDATED PART:
        // Generate QR Code button now opens QR screen
        // ===================================================
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const GenerateQRCodeScreen(),
            ),
          );
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

  // =========================================================
  // SECTION TITLE
  // =========================================================
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

  // =========================================================
  // STAT CARD
  // =========================================================
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
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _showDialog(
          context,
          '$title Details',
          details,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4D9DF),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: slate,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
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
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
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

  // =========================================================
  // DURATION CARD
  // =========================================================
  Widget _durationCard(
    BuildContext context,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _showDialog(
          context,
          'Duration Details',
          'Total Active Time: 6 hours\n'
          'Average Duration per Walk: 30 minutes\n'
          'Pace Efficiency: Good',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4D9DF),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: Colors.green,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Active Duration',
                    style: TextStyle(
                      color: slate,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '6 hrs',
                      style: TextStyle(
                        color: navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
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

  // =========================================================
  // REPORT CARD
  // =========================================================
  Widget _reportCard(
    BuildContext context,
  ) {
    return InkWell(
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
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
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
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.assessment_outlined,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Report Card',
                    style: TextStyle(
                      color: slate,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Performance',
                      style: TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
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

  // =========================================================
  // WALK CARD
  // =========================================================
  Widget _walkCard(
    BuildContext context, {
    required String id,
    required String time,
    required String date,
    required String distance,
    required String duration,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        _showDialog(
          context,
          'Walk Details',
          'Walk ID: $id\n'
          'Time: $time\n'
          'Date: $date\n'
          'Duration: $duration\n'
          'Distance: $distance\n'
          'Route: Park Lane to Block C\n'
          'Status: Completed Successfully',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4D9DF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.pets,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$id • $time',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$distance • $duration • $date',
                    style: const TextStyle(
                      color: slate,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 7),
            const Icon(
              Icons.arrow_forward_ios,
              size: 13,
              color: Color(0xFF8A96A3),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DETAILS DIALOG
  // =========================================================
  void _showDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F8FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              color: slate,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // QR DIALOG
  // =========================================================
  void _showQrDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF7F8FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Generate QR Code',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan this QR code for your active walk session verification.',
                style: TextStyle(
                  color: slate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(
                      0xFFD4D9DF,
                    ),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 150,
                  color: orange,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
