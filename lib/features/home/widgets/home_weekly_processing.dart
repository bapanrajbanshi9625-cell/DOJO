import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // ==========================================================
  // CURRENT OWNER UID
  // ==========================================================

  String? get _ownerUid {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();

    if (uid == null || uid.isEmpty) {
      return null;
    }

    return uid;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final uid = _ownerUid;

    if (uid == null) {
      return _buildWithData(
        context,
        totalWalks: 0,
        totalDistance: 0,
        averageDistance: 0,
        longestDistance: 0,
        totalDurationMinutes: 0,
        averageDurationMinutes: 0,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('walkHistory')
          .where('ownerId', isEqualTo: uid)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildWithData(
            context,
            totalWalks: 0,
            totalDistance: 0,
            averageDistance: 0,
            longestDistance: 0,
            totalDurationMinutes: 0,
            averageDurationMinutes: 0,
          );
        }

        final documents = snapshot.data?.docs ?? [];

        final weeklyData = _calculateCurrentWeek(
          documents,
          uid,
        );

        return _buildWithData(
          context,
          totalWalks: weeklyData.totalWalks,
          totalDistance: weeklyData.totalDistance,
          averageDistance: weeklyData.averageDistance,
          longestDistance: weeklyData.longestDistance,
          totalDurationMinutes:
              weeklyData.totalDurationMinutes,
          averageDurationMinutes:
              weeklyData.averageDurationMinutes,
        );
      },
    );
  }

  // ==========================================================
  // CURRENT WEEK CALCULATION
  //
  // MONDAY -> SUNDAY
  // ==========================================================

  _WeeklyData _calculateCurrentWeek(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
    String currentUid,
  ) {
    final now = DateTime.now();

    // DateTime.weekday:
    // Monday = 1
    // Sunday = 7

    final startOfToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final weekStart = startOfToday.subtract(
      Duration(
        days: startOfToday.weekday - DateTime.monday,
      ),
    );

    final nextWeekStart = weekStart.add(
      const Duration(days: 7),
    );

    int totalWalks = 0;
    double totalDistance = 0;
    double longestDistance = 0;
    int totalDurationMinutes = 0;

    for (final document in documents) {
      final data = document.data();

      // ------------------------------------------------------
      // EXTRA OWNER SAFETY CHECK
      // ------------------------------------------------------

      final ownerId = _readString(
        data['ownerId'],
      );

      if (ownerId != currentUid) {
        continue;
      }

      // ------------------------------------------------------
      // COMPLETED AT
      // ------------------------------------------------------

      final completedAt = _readDateTime(
        data['completedAt'],
      );

      if (completedAt == null) {
        continue;
      }

      // ------------------------------------------------------
      // ONLY CURRENT MONDAY -> NEXT MONDAY
      // ------------------------------------------------------

      if (completedAt.isBefore(weekStart) ||
          !completedAt.isBefore(nextWeekStart)) {
        continue;
      }

      // ------------------------------------------------------
      // OPTIONAL STATUS CHECK
      //
      // If status exists and is not completed, skip it.
      // If status field does not exist, the record is allowed.
      // ------------------------------------------------------

      final status = _readString(
        data['status'],
      ).toLowerCase();

      if (status.isNotEmpty) {
        const completedStatuses = {
          'completed',
          'complete',
          'done',
          'finished',
          'success',
          'successful',
        };

        if (!completedStatuses.contains(status)) {
          continue;
        }
      }

      // ------------------------------------------------------
      // WALK COUNT
      // ------------------------------------------------------

      totalWalks++;

      // ------------------------------------------------------
      // DISTANCE
      // ------------------------------------------------------

      final distance = _readDouble(
        data['distance'],
      );

      if (distance != null && distance >= 0) {
        totalDistance += distance;

        if (distance > longestDistance) {
          longestDistance = distance;
        }
      }

      // ------------------------------------------------------
      // DURATION
      //
      // Supports:
      // durationMinutes
      // duration
      // durationInMinutes
      // ------------------------------------------------------

      final durationMinutes = _readDurationMinutes(
        data,
      );

      if (durationMinutes != null &&
          durationMinutes >= 0) {
        totalDurationMinutes += durationMinutes;
      }
    }

    final averageDistance = totalWalks == 0
        ? 0.0
        : totalDistance / totalWalks;

    final averageDurationMinutes = totalWalks == 0
        ? 0
        : (totalDurationMinutes / totalWalks).round();

    return _WeeklyData(
      totalWalks: totalWalks,
      totalDistance: totalDistance,
      averageDistance: averageDistance,
      longestDistance: longestDistance,
      totalDurationMinutes: totalDurationMinutes,
      averageDurationMinutes: averageDurationMinutes,
    );
  }

  // ==========================================================
  // BUILD UI
  // ==========================================================

  Widget _buildWithData(
    BuildContext context, {
    required int totalWalks,
    required double totalDistance,
    required double averageDistance,
    required double longestDistance,
    required int totalDurationMinutes,
    required int averageDurationMinutes,
  }) {
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
                  value: '$totalWalks',
                  icon: Icons.pets,
                  iconColor: orange,
                  details:
                      'Completed Walks: $totalWalks\n'
                      'Average Walks/Day: '
                      '${_averageWalksPerDay(totalWalks)}\n'
                      'Status: ${_walkStatus(totalWalks)}',
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _statCard(
                  title: 'Distance',
                  value: _formatNumber(totalDistance),
                  suffix: ' km',
                  icon: Icons.route,
                  iconColor: const Color(0xFF2196F3),
                  details:
                      'Total Distance: '
                      '${_formatNumber(totalDistance)} km\n'
                      'Average per Walk: '
                      '${_formatNumber(averageDistance)} km\n'
                      'Longest Walk: '
                      '${_formatNumber(longestDistance)} km',
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _durationCard(
                  totalDurationMinutes,
                  averageDurationMinutes,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: _reportCard(
                  totalWalks,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STAT CARD
  // ==========================================================

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

  // ==========================================================
  // DURATION CARD
  // ==========================================================

  Widget _durationCard(
    int totalDurationMinutes,
    int averageDurationMinutes,
  ) {
    final totalText = _formatDuration(
      totalDurationMinutes,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        onDetails(
          'Duration Details',
          'Total Active Time: $totalText\n'
          'Average Duration per Walk: '
          '${_formatDuration(averageDurationMinutes)}\n'
          'Pace Efficiency: ${_paceStatus(
            averageDurationMinutes,
          )}',
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

            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Duration',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: slate,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      totalText,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 20,
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

  // ==========================================================
  // REPORT CARD
  // ==========================================================

  Widget _reportCard(
    int totalWalks,
  ) {
    final reportStatus = totalWalks > 0
        ? 'Active'
        : 'No Walks';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        onDetails(
          'Report Card',
          'Current Week Report: '
          '$reportStatus ($totalWalks Walks)\n\n'
          'Weekly Cycle: Monday - Sunday\n\n'
          'Counting resets automatically every Monday.',
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

  // ==========================================================
  // HELPERS
  // ==========================================================

  static String _readString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  static double? _readDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final cleaned = value
          .trim()
          .replaceAll(',', '')
          .replaceAll('km', '')
          .trim();

      return double.tryParse(cleaned);
    }

    return null;
  }

  static int? _readDurationMinutes(
    Map<String, dynamic> data,
  ) {
    final candidates = [
      data['durationMinutes'],
      data['durationInMinutes'],
      data['duration'],
    ];

    for (final value in candidates) {
      if (value == null) {
        continue;
      }

      if (value is num) {
        return value.round();
      }

      if (value is String) {
        final text = value.trim().toLowerCase();

        final direct = int.tryParse(text);

        if (direct != null) {
          return direct;
        }

        final hourMatch = RegExp(
          r'(\d+(?:\.\d+)?)\s*(?:h|hr|hrs|hour|hours)',
        ).firstMatch(text);

        final minuteMatch = RegExp(
          r'(\d+)\s*(?:m|min|mins|minute|minutes)',
        ).firstMatch(text);

        double totalMinutes = 0;

        if (hourMatch != null) {
          totalMinutes +=
              double.parse(hourMatch.group(1)!) * 60;
        }

        if (minuteMatch != null) {
          totalMinutes +=
              double.parse(minuteMatch.group(1)!);
        }

        if (totalMinutes > 0) {
          return totalMinutes.round();
        }
      }
    }

    return null;
  }

  static String _formatNumber(double value) {
    if (value == 0) {
      return '0';
    }

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  static String _formatDuration(int minutes) {
    if (minutes <= 0) {
      return '0 hrs';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '$remainingMinutes mins';
    }

    if (remainingMinutes == 0) {
      return '$hours hrs';
    }

    return '$hours h ${remainingMinutes}m';
  }

  static String _averageWalksPerDay(
    int totalWalks,
  ) {
    if (totalWalks == 0) {
      return '0';
    }

    final now = DateTime.now();

    // Monday = 1 ... Sunday = 7
    final daysSoFar = now.weekday;

    final average = totalWalks / daysSoFar;

    return average.toStringAsFixed(1);
  }

  static String _walkStatus(
    int totalWalks,
  ) {
    if (totalWalks == 0) {
      return 'No Walks';
    }

    return 'On Track';
  }

  static String _paceStatus(
    int averageDurationMinutes,
  ) {
    if (averageDurationMinutes <= 0) {
      return 'No Data';
    }

    if (averageDurationMinutes <= 45) {
      return 'Good';
    }

    if (averageDurationMinutes <= 90) {
      return 'Normal';
    }

    return 'Long Walks';
  }
}

// ==========================================================
// WEEKLY DATA MODEL
// ==========================================================

class _WeeklyData {
  const _WeeklyData({
    required this.totalWalks,
    required this.totalDistance,
    required this.averageDistance,
    required this.longestDistance,
    required this.totalDurationMinutes,
    required this.averageDurationMinutes,
  });

  final int totalWalks;
  final double totalDistance;
  final double averageDistance;
  final double longestDistance;
  final int totalDurationMinutes;
  final int averageDurationMinutes;
}
