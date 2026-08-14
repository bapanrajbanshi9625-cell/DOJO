import 'package:flutter/material.dart';

import '../models/walk_model.dart';
import '../services/walks_firestore_service.dart';
import '../utils/walks_date_utils.dart';
import 'day_walk_container.dart';

class ThisWeekSection extends StatelessWidget {
  const ThisWeekSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final service =
        WalksFirestoreService();

    final monday =
        WalksDateUtils.monday(
      DateTime.now(),
    );

    return StreamBuilder<List<WalkModel>>(
      stream: service.watchOwnerWalks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        final walks =
            snapshot.data ?? [];

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                22,
                20,
                10,
              ),
              child: Text(
                'This Week',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w800,
                  color: Color(0xFF172337),
                ),
              ),
            ),

            ...List.generate(
              7,
              (index) {
                final day =
                    monday.add(
                  Duration(days: index),
                );

                final dayWalks =
                    walks.where(
                  (walk) =>
                      WalksDateUtils.sameDay(
                    walk.date,
                    day,
                  ),
                ).toList();

                return DayWalkContainer(
                  day: day,
                  walks: dayWalks,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
