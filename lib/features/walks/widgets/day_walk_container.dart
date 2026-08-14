import 'package:flutter/material.dart';

import '../models/walk_model.dart';
import '../utils/walks_date_utils.dart';
import 'walk_tile.dart';

class DayWalkContainer extends StatelessWidget {
  final DateTime day;
  final List<WalkModel> walks;

  const DayWalkContainer({
    super.key,
    required this.day,
    required this.walks,
  });

  @override
  Widget build(BuildContext context) {
    final today = WalksDateUtils.sameDay(
      day,
      DateTime.now(),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        8,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: today
              ? const Color(0xFFE45D32)
                  .withOpacity(.35)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: today
                      ? const Color(0xFFE45D32)
                          .withOpacity(.10)
                      : const Color(0xFFF3F4F6),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: today
                            ? const Color(0xFFE45D32)
                            : const Color(0xFF172337),
                      ),
                    ),
                    Text(
                      WalksDateUtils.month(day),
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      WalksDateUtils.dayName(day),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172337),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      walks.isEmpty
                          ? 'No walks'
                          : '${walks.length} walks',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              if (today)
                const Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE45D32),
                  ),
                ),
            ],
          ),

          if (walks.isNotEmpty)
            const SizedBox(height: 10),

          if (walks.isNotEmpty)
            SizedBox(
              height: walks.length > 3
                  ? 205
                  : null,
              child: ListView.builder(
                itemCount: walks.length,
                physics: walks.length > 3
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemBuilder: (_, index) {
                  return WalkTile(
                    walk: walks[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
