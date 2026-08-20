import 'package:flutter/material.dart';

class HomePastWalk extends StatelessWidget {
  const HomePastWalk({
    super.key,
    required this.onDetails,
  });

  final void Function(
    String title,
    String content,
  ) onDetails;

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _walkCard(
          id: '#WID-9842',
          time: '08:30 AM',
          date: '04 Aug 2026',
          distance: '2.1 km',
          duration: '30 mins',
        ),

        const SizedBox(height: 8),

        _walkCard(
          id: '#WID-9817',
          time: '07:15 AM',
          date: '03 Aug 2026',
          distance: '1.8 km',
          duration: '27 mins',
        ),
      ],
    );
  }

  Widget _walkCard({
    required String id,
    required String time,
    required String date,
    required String distance,
    required String duration,
  }) {
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
          'Route: Park Lane to Block C\n'
          'Status: Completed Successfully',
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

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '$id • $time',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: slate,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                'DONE',
                style: TextStyle(
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
}
