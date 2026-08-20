import 'package:flutter/material.dart';

class HomePastWalk extends StatelessWidget {
  const HomePastWalk({
    super.key,
    required this.walks,
    required this.onDetails,
  });

  // =====================================================
  // FIRESTORE DATA
  // =====================================================

  final List<Map<String, dynamic>> walks;

  final void Function(
    String title,
    String content,
  ) onDetails;

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    // ===================================================
    // EMPTY STATE
    // ===================================================

    if (walks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD4D9DF),
          ),
        ),
        child: const Text(
          'No past walks found.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: slate,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // ===================================================
    // PAST WALKS
    // ===================================================

    return Column(
      children: [
        for (int i = 0; i < walks.length; i++) ...[
          _walkCard(
            walk: walks[i],
          ),

          if (i != walks.length - 1)
            const SizedBox(height: 8),
        ],
      ],
    );
  }

  // =====================================================
  // WALK CARD
  // =====================================================

  Widget _walkCard({
    required Map<String, dynamic> walk,
  }) {
    // ===================================================
    // SAFE FIRESTORE VALUES
    // ===================================================

    final String id = _stringValue(
      walk['walkId'] ??
          walk['id'] ??
          walk['walkID'],
      fallback: 'Walk',
    );

    final String time = _stringValue(
      walk['timeFormatted'] ??
          walk['time'] ??
          walk['startTime'],
      fallback: '--',
    );

    final String date = _stringValue(
      walk['date'] ??
          walk['walkDate'] ??
          walk['createdDate'],
      fallback: '--',
    );

    final String distance = _formatDistance(
      walk['distance'] ??
          walk['distanceKm'] ??
          walk['totalDistance'],
    );

    final String duration = _formatDuration(
      walk['durationMinutes'] ??
          walk['duration'] ??
          walk['totalDuration'],
    );

    final String route = _stringValue(
      walk['route'] ??
          walk['routeName'] ??
          walk['location'],
      fallback: 'Route information unavailable',
    );

    final String status = _stringValue(
      walk['status'],
      fallback: 'Completed',
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),

      onTap: () {
        onDetails(
          'Walk Details',
          'Walk ID: $id\n'
          'Time: $time\n'
          'Date: $date\n'
          'Duration: $duration\n'
          'Distance: $distance\n'
          'Route: $route\n'
          'Status: $status',
        );
      },

      child: Container(
        padding: const EdgeInsets.all(11),

        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),

          borderRadius: BorderRadius.circular(14),

          border: Border.all(
            color: const Color(0xFFD4D9DF),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          children: [
            // =========================================
            // ICON
            // =========================================

            Container(
              height: 42,
              width: 42,

              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Icon(
                Icons.pets,
                color: Colors.green,
                size: 21,
              ),
            ),

            const SizedBox(width: 10),

            // =========================================
            // WALK INFORMATION
            // =========================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    '$id • $time',

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '$distance • $duration • $date',

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: slate,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // =========================================
            // STATUS
            // =========================================

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),

              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(7),
              ),

              child: Text(
                status.toUpperCase(),

                maxLines: 1,

                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(width: 6),

            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Color(0xFF8A96A3),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // STRING HELPER
  // =====================================================

  String _stringValue(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result = value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  // =====================================================
  // DISTANCE FORMAT
  // =====================================================

  String _formatDistance(dynamic value) {
    if (value == null) {
      return '--';
    }

    if (value is num) {
      return '${value.toString()} km';
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return '--';
    }

    if (text.toLowerCase().contains('km')) {
      return text;
    }

    return '$text km';
  }

  // =====================================================
  // DURATION FORMAT
  // =====================================================

  String _formatDuration(dynamic value) {
    if (value == null) {
      return '--';
    }

    if (value is num) {
      return '${value.toString()} mins';
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return '--';
    }

    return text;
  }
}
