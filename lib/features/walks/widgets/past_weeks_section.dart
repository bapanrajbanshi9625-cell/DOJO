import 'package:flutter/material.dart';

import '../models/walk_model.dart';
import '../services/walks_firestore_service.dart';
import '../utils/walks_date_utils.dart';
import 'walk_tile.dart';

class PastWeeksSection extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const PastWeeksSection({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  Future<void> _chooseDate(
    BuildContext context,
  ) async {
    final selected =
        await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate:
          DateTime.now().subtract(
        const Duration(days: 1),
      ),
      helpText:
          'Choose a date from a past week',
    );

    if (selected != null) {
      onDateChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monday =
        WalksDateUtils.monday(
      selectedDate,
    );

    final sunday =
        monday.add(
      const Duration(days: 6),
    );

    return StreamBuilder<List<WalkModel>>(
      stream:
          WalksFirestoreService()
              .watchOwnerWalks(),
      builder: (context, snapshot) {
        final walks =
            snapshot.data ?? [];

        final weekWalks =
            walks.where(
          (walk) =>
              WalksDateUtils.isInWeek(
            walk.date,
            monday,
          ),
        ).toList();

        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                10,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Past Weeks Walks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF172337),
                      ),
                    ),
                  ),

                  TextButton.icon(
                    onPressed: () =>
                        _chooseDate(context),
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                    ),
                    label:
                        const Text('Choose'),
                    style:
                        TextButton.styleFrom(
                      foregroundColor:
                          const Color(
                        0xFFE45D32,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Container(
                padding:
                    const EdgeInsets.all(14),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${WalksDateUtils.shortDate(monday)} - ${WalksDateUtils.shortDate(sunday)}',
                      style:
                          const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(0xFF172337),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (weekWalks.isEmpty)
                      const Center(
                        child: Padding(
                          padding:
                              EdgeInsets.all(18),
                          child: Text(
                            'No walks this week',
                            style: TextStyle(
                              color:
                                  Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                    else
                      ...weekWalks.map(
                        (walk) =>
                            WalkTile(
                          walk: walk,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
