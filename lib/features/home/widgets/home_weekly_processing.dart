import 'package:flutter/material.dart';

class HomeWeeklyProcessing extends StatelessWidget {
  const HomeWeeklyProcessing({
    super.key,
    required this.onDetails,
  });

  final void Function(
    String title,
    String content,
  ) onDetails;

  static const Color orange = Color(0xFFF4511E);
  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD6DAE0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 11,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  title: 'Total Walks',
                  value: '12',
                  icon: Icons.pets,
                  iconColor: orange,
                  details:
                      'Completed Walks: 12\n'
                      'Average Walks/Day: 1.5\n'
                      'Status: On Track',
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _statCard(
                  title: 'Distance',
                  value: '24.5',
                  suffix: ' km',
                  icon: Icons.route,
                  iconColor: const Color(0xFF2196F3),
                  details:
                      'Total Distance: 24.5 km\n'
                      'Average per Walk: 2.04 km\n'
                      'Longest Walk: 3.5 km',
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _durationCard(),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _reportCard(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    String suffix = '',
    required IconData icon,
    required Color iconColor,
    required String details,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        onDetails(
          '$title Details',
          details,
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 88,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD4D9DF),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: slate,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

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
                              fontSize: 20,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        onDetails(
          'Duration Details',
          'Total Active Time: 6 hours\n'
          'Average Duration per Walk: 30 minutes\n'
          'Pace Efficiency: Good',
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 88,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF2F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD4D9DF),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.timer_outlined,
                color: Colors.green,
                size: 22,
              ),
            ),

            const SizedBox(width: 9),

            const Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Duration',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: slate,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '6 hrs',
                    style: TextStyle(
                      color: navy,
                      fontSize: 20,
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

  Widget _reportCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        onDetails(
          'Report Card',
          'First Week Report: Completed (10 Walks)\n\n'
          'Current Week Report: Active (12 Walks)\n\n'
          'Current Week Start: 03 Aug 2026',
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 88,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1EA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: orange.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assessment_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 9),

            const Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Card',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: slate,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Performance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: navy,
                      fontSize: 17,
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
}
