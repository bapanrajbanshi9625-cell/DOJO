// File location:
// lib/features/home/services/home_data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// HOME DATA SERVICE
/// ============================================================
///
/// HomeScreen के लिए Firestore data service.
///
/// यह service:
///   • Current Live Walk सुनती है
///   • Past Walks fetch करती है
///   • Past Walks stream देती है
///   • Weekly statistics निकालती है
///   • Distance / Duration format करती है
///
/// ============================================================

class HomeDataService {
  HomeDataService._();

  static final HomeDataService instance =
      HomeDataService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get currentOwnerUid {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      return null;
    }

    return uid;
  }

  // ============================================================
  // LIVE WALK
  // ============================================================

  static const String liveWalkCollection =
      'active_walks';

  /// HomeScreen को current active/live walk
  /// real-time में सुनाता है.
  Stream<HomeLiveWalk?> liveWalkStream() {
    final String? ownerUid = currentOwnerUid;

    if (ownerUid == null) {
      return Stream<HomeLiveWalk?>.value(null);
    }

    return _firestore
        .collection(liveWalkCollection)
        .where(
          'ownerId',
          isEqualTo: ownerUid,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (snapshot.docs.isEmpty) {
          return null;
        }

        for (
          final QueryDocumentSnapshot<Map<String, dynamic>>
              doc
              in snapshot.docs
        ) {
          final Map<String, dynamic> data =
              doc.data();

          if (_isLiveWalk(data)) {
            return HomeLiveWalk.fromFirestore(
              doc.id,
              data,
            );
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // LIVE WALK STATUS CHECK
  // ============================================================

  bool _isLiveWalk(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // Boolean fields
    // ----------------------------------------------------------

    final dynamic isLive =
        data['isLive'] ??
        data['live'] ??
        data['liveWalk'] ??
        data['walkLive'];

    if (isLive is bool) {
      return isLive;
    }

    // ----------------------------------------------------------
    // Status fields
    // ----------------------------------------------------------

    final String status =
        _stringValue(
          data['status'],
        ).toLowerCase();

    final String walkStatus =
        _stringValue(
          data['walkStatus'],
        ).toLowerCase();

    final String rideStatus =
        _stringValue(
          data['rideStatus'],
        ).toLowerCase();

    final String currentStatus =
        _stringValue(
          data['currentStatus'],
        ).toLowerCase();

    const List<String> liveValues = [
      'live',
      'active',
      'started',
      'in_progress',
      'in progress',
    ];

    if (liveValues.contains(status)) {
      return true;
    }

    if (liveValues.contains(walkStatus)) {
      return true;
    }

    if (liveValues.contains(rideStatus)) {
      return true;
    }

    if (liveValues.contains(currentStatus)) {
      return true;
    }

    return false;
  }

  // ============================================================
  // PAST WALKS
  // ============================================================

  static const String walkHistoryCollection =
      'walk_history';

  Future<List<HomePastWalk>> getPastWalks({
    int limit = 20,
  }) async {
    final String? ownerUid = currentOwnerUid;

    if (ownerUid == null) {
      return <HomePastWalk>[];
    }

    final List<HomePastWalk> result =
        <HomePastWalk>[];

    // ----------------------------------------------------------
    // ownerId
    // ----------------------------------------------------------

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _firestore
              .collection(
                walkHistoryCollection,
              )
              .where(
                'ownerId',
                isEqualTo: ownerUid,
              )
              .limit(limit)
              .get();

      for (
        final QueryDocumentSnapshot<
            Map<String, dynamic>> doc
            in snapshot.docs
      ) {
        result.add(
          HomePastWalk.fromFirestore(
            doc.id,
            doc.data(),
          ),
        );
      }
    } catch (_) {
      // Fallback नीचे किया जाएगा.
    }

    // ----------------------------------------------------------
    // ownerUid fallback
    // ----------------------------------------------------------

    if (result.isEmpty) {
      try {
        final QuerySnapshot<Map<String, dynamic>>
            snapshot =
            await _firestore
                .collection(
                  walkHistoryCollection,
                )
                .where(
                  'ownerUid',
                  isEqualTo: ownerUid,
                )
                .limit(limit)
                .get();

        for (
          final QueryDocumentSnapshot<
              Map<String, dynamic>> doc
              in snapshot.docs
        ) {
          result.add(
            HomePastWalk.fromFirestore(
              doc.id,
              doc.data(),
            ),
          );
        }
      } catch (_) {
        // Safe fallback.
      }
    }

    // ----------------------------------------------------------
    // Latest first
    // ----------------------------------------------------------

    result.sort(
      (HomePastWalk a, HomePastWalk b) {
        return b.date.compareTo(a.date);
      },
    );

    return result.take(limit).toList();
  }

  // ============================================================
  // PAST WALKS STREAM
  // ============================================================

  Stream<List<HomePastWalk>> pastWalksStream({
    int limit = 20,
  }) {
    final String? ownerUid = currentOwnerUid;

    if (ownerUid == null) {
      return Stream<List<HomePastWalk>>.value(
        <HomePastWalk>[],
      );
    }

    return _firestore
        .collection(walkHistoryCollection)
        .where(
          'ownerId',
          isEqualTo: ownerUid,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final List<HomePastWalk> walks =
            snapshot.docs
                .map(
                  (
                    QueryDocumentSnapshot<
                        Map<String, dynamic>> doc,
                  ) {
                    return HomePastWalk.fromFirestore(
                      doc.id,
                      doc.data(),
                    );
                  },
                )
                .toList();

        walks.sort(
          (HomePastWalk a, HomePastWalk b) {
            return b.date.compareTo(a.date);
          },
        );

        return walks.take(limit).toList();
      },
    );
  }

  // ============================================================
  // WEEKLY STATISTICS
  // ============================================================

  Future<HomeWeeklyStats> getWeeklyStats() async {
    final List<HomePastWalk> walks =
        await getPastWalks(
      limit: 100,
    );

    final DateTime now =
        DateTime.now();

    final DateTime startOfWeek =
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(
          Duration(
            days: now.weekday - 1,
          ),
        );

    final List<HomePastWalk> weeklyWalks =
        walks
            .where(
              (HomePastWalk walk) {
                return !walk.date.isBefore(
                  startOfWeek,
                );
              },
            )
            .toList();

    double totalDistance = 0;

    int totalDurationMinutes = 0;

    for (
      final HomePastWalk walk
          in weeklyWalks
    ) {
      totalDistance += walk.distanceKm;

      totalDurationMinutes +=
          walk.durationMinutes;
    }

    return HomeWeeklyStats(
      totalWalks: weeklyWalks.length,
      totalDistanceKm: totalDistance,
      totalDurationMinutes:
          totalDurationMinutes,
      walks: weeklyWalks,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static double _doubleValue(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(
                ',',
                '',
              ),
        ) ??
        0;
  }

  static int _intValue(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  static DateTime _dateValue(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(
            0,
          );
    }

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }

  // ============================================================
  // FORMATTERS
  // ============================================================

  static String formatDistance(
    double km,
  ) {
    if (km <= 0) {
      return '0.0 km';
    }

    return '${km.toStringAsFixed(1)} km';
  }

  static String formatDuration(
    int minutes,
  ) {
    if (minutes <= 0) {
      return '0 mins';
    }

    final int hours =
        minutes ~/ 60;

    final int remainingMinutes =
        minutes % 60;

    if (hours > 0) {
      if (remainingMinutes == 0) {
        return '$hours hrs';
      }

      return '$hours hrs '
          '$remainingMinutes mins';
    }

    return '$minutes mins';
  }
}

// ============================================================
// HOME LIVE WALK MODEL
// ============================================================

class HomeLiveWalk {
  final String documentId;
  final String walkId;
  final String walkerUid;
  final String walkerName;
  final String? walkerPhone;
  final String status;
  final DateTime? startedAt;

  const HomeLiveWalk({
    required this.documentId,
    required this.walkId,
    required this.walkerUid,
    required this.walkerName,
    required this.walkerPhone,
    required this.status,
    required this.startedAt,
  });

  factory HomeLiveWalk.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final dynamic startedAtValue =
        data['startedAt'] ??
        data['startTime'] ??
        data['started_at'];

    final String walkerNameValue =
        HomeDataService._stringValue(
      data['walkerName'] ??
          data['walker'],
    );

    final String walkerPhoneValue =
        HomeDataService._stringValue(
      data['walkerPhone'] ??
          data['phone'] ??
          data['walkerMobile'],
    );

    return HomeLiveWalk(
      documentId: documentId,

      walkId:
          HomeDataService._stringValue(
        data['walkId'] ??
            data['id'] ??
            documentId,
      ),

      walkerUid:
          HomeDataService._stringValue(
        data['walkerUid'] ??
            data['walkerId'] ??
            data['walkerUID'],
      ),

      walkerName:
          walkerNameValue.isEmpty
              ? 'Walker'
              : walkerNameValue,

      walkerPhone:
          walkerPhoneValue.isEmpty
              ? null
              : walkerPhoneValue,

      status:
          HomeDataService._stringValue(
        data['status'] ??
            data['walkStatus'] ??
            data['currentStatus'],
      ),

      startedAt:
          startedAtValue == null
              ? null
              : HomeDataService._dateValue(
                  startedAtValue,
                ),
    );
  }
}

// ============================================================
// HOME PAST WALK MODEL
// ============================================================

class HomePastWalk {
  final String documentId;
  final String walkId;
  final String ownerUid;
  final String walkerUid;
  final String walkerName;
  final String dogName;
  final double distanceKm;
  final int durationMinutes;
  final int steps;
  final DateTime date;
  final String timeFormatted;
  final String status;

  const HomePastWalk({
    required this.documentId,
    required this.walkId,
    required this.ownerUid,
    required this.walkerUid,
    required this.walkerName,
    required this.dogName,
    required this.distanceKm,
    required this.durationMinutes,
    required this.steps,
    required this.date,
    required this.timeFormatted,
    required this.status,
  });

  factory HomePastWalk.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final dynamic dateValue =
        data['date'] ??
        data['createdAt'] ??
        data['completedAt'] ??
        data['endedAt'] ??
        data['startTime'];

    final dynamic distanceValue =
        data['distanceKm'] ??
        data['distance'] ??
        data['totalDistance'];

    final dynamic durationValue =
        data['durationMinutes'] ??
        data['duration'] ??
        data['totalDuration'];

    final dynamic stepsValue =
        data['steps'] ??
        data['totalSteps'];

    final String walkerNameValue =
        HomeDataService._stringValue(
      data['walkerName'] ??
          data['walker'],
    );

    return HomePastWalk(
      documentId: documentId,

      walkId:
          HomeDataService._stringValue(
        data['walkId'] ??
            data['id'] ??
            documentId,
      ),

      ownerUid:
          HomeDataService._stringValue(
        data['ownerUid'] ??
            data['ownerId'],
      ),

      walkerUid:
          HomeDataService._stringValue(
        data['walkerUid'] ??
            data['walkerId'],
      ),

      walkerName:
          walkerNameValue.isEmpty
              ? 'Walker'
              : walkerNameValue,

      dogName:
          HomeDataService._stringValue(
        data['dogName'] ??
            data['petName'],
      ),

      distanceKm:
          HomeDataService._doubleValue(
        distanceValue,
      ),

      durationMinutes:
          HomeDataService._intValue(
        durationValue,
      ),

      steps:
          HomeDataService._intValue(
        stepsValue,
      ),

      date:
          dateValue == null
              ? DateTime.fromMillisecondsSinceEpoch(
                  0,
                )
              : HomeDataService._dateValue(
                  dateValue,
                ),

      timeFormatted:
          HomeDataService._stringValue(
        data['timeFormatted'] ??
            data['time'] ??
            data['formattedTime'],
      ),

      status:
          HomeDataService._stringValue(
            data['status'] ??
                data['walkStatus'] ??
                'Completed',
          ),
    );
  }
}

// ============================================================
// HOME WEEKLY STATS MODEL
// ============================================================

class HomeWeeklyStats {
  final int totalWalks;
  final double totalDistanceKm;
  final int totalDurationMinutes;
  final List<HomePastWalk> walks;

  const HomeWeeklyStats({
    required this.totalWalks,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.walks,
  });

  String get formattedDistance {
    return HomeDataService.formatDistance(
      totalDistanceKm,
    );
  }

  String get formattedDuration {
    return HomeDataService.formatDuration(
      totalDurationMinutes,
    );
  }

  double get averageDistance {
    if (totalWalks == 0) {
      return 0;
    }

    return totalDistanceKm / totalWalks;
  }

  int get averageDuration {
    if (totalWalks == 0) {
      return 0;
    }

    return totalDurationMinutes ~/ totalWalks;
  }
}
