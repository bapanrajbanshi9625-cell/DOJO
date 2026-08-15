import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'custom_app_bar.dart';

class WalkHistoryScreen extends StatelessWidget {
  const WalkHistoryScreen({super.key});

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color background = Color(0xFFEDEFF2);
  static const Color card = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,

      // =========================================
      // DOJO WALK APP BAR
      // =========================================

      appBar: const CustomAppBar(),

      body: user == null
          ? const _NotLoggedInView()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('walk_history')
                  .where(
                    'ownerUid',
                    isEqualTo: user.uid,
                  )
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
                  .snapshots(),

              builder: (context, snapshot) {
                // =================================
                // LOADING
                // =================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                // =================================
                // ERROR
                // =================================

                if (snapshot.hasError) {
                  return _ErrorView(
                    message:
                        'Unable to load walk history.',
                    onRetry: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const WalkHistoryScreen(),
                        ),
                      );
                    },
                  );
                }

                final docs =
                    snapshot.data?.docs ?? [];

                // =================================
                // EMPTY
                // =================================

                if (docs.isEmpty) {
                  return const _EmptyWalkView();
                }

                // =================================
                // WALK HISTORY
                // =================================

                return RefreshIndicator(
                  color: AppColors.primary,

                  onRefresh: () async {
                    // StreamBuilder automatically refreshes.
                    await Future<void>.delayed(
                      const Duration(
                        milliseconds: 300,
                      ),
                    );
                  },

                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),

                    padding:
                        const EdgeInsets.fromLTRB(
                      15,
                      18,
                      15,
                      110,
                    ),

                    children: [
                      // =================================
                      // HEADER
                      // =================================

                      _sectionTitle(
                        'Walk History',
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'View your completed walking sessions.',
                        style: TextStyle(
                          color: slate,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // =================================
                      // TOTAL
                      // =================================

                      Container(
                        padding:
                            const EdgeInsets.all(16),

                        decoration:
                            BoxDecoration(
                          color: card,
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFFD6DAE0,
                            ),
                          ),
                        ),

                        child: Row(
                          children: [
                            Container(
                              height: 45,
                              width: 45,

                              decoration:
                                  BoxDecoration(
                                color: AppColors
                                    .primary
                                    .withOpacity(
                                  0.12,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  13,
                                ),
                              ),

                              child: const Icon(
                                Icons.pets,
                                color:
                                    AppColors.primary,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'Total Walks',
                                    style: TextStyle(
                                      color: slate,
                                      fontSize: 11,
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 3,
                                  ),
                                  Text(
                                    'Completed Sessions',
                                    style: TextStyle(
                                      color: navy,
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight
                                              .w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              '${docs.length}',
                              style:
                                  const TextStyle(
                                color:
                                    AppColors.primary,
                                fontSize: 24,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // =================================
                      // HISTORY LIST
                      // =================================

                      ...docs.map(
                        (doc) => Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          child: _WalkCard(
                            data: doc.data(),
                            walkId: doc.id,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ===============================================
  // SECTION TITLE
  // ===============================================

  static Widget _sectionTitle(
    String title,
  ) {
    return Row(
      children: [
        Container(
          height: 21,
          width: 4,

          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius:
                BorderRadius.circular(5),
          ),
        ),

        const SizedBox(width: 9),

        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

// =====================================================
// WALK CARD
// =====================================================

class _WalkCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String walkId;

  const _WalkCard({
    required this.data,
    required this.walkId,
  });

  @override
  Widget build(BuildContext context) {
    final String dogName =
        _stringValue(
          data['dogName'],
          fallback: 'Dog',
        );

    final String walkerName =
        _stringValue(
          data['walkerName'],
          fallback: 'Walker',
        );

    final String distance =
        _formatDistance(
      data['distanceKm'],
    );

    final String duration =
        _formatDuration(
      data['durationMinutes'],
    );

    final String date =
        _formatDate(
      data['date'] ??
          data['createdAt'],
    );

    final String status =
        _stringValue(
          data['status'],
          fallback: 'Completed',
        );

    return InkWell(
      borderRadius:
          BorderRadius.circular(17),

      onTap: () {
        _showWalkDetails(
          context,
          dogName: dogName,
          walkerName: walkerName,
          distance: distance,
          duration: duration,
          date: date,
          status: status,
          walkId: walkId,
        );
      },

      child: Container(
        padding:
            const EdgeInsets.all(14),

        decoration:
            BoxDecoration(
          color: const Color(
            0xFFF7F8FA,
          ),

          borderRadius:
              BorderRadius.circular(17),

          border: Border.all(
            color: const Color(
              0xFFD4D9DF,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.05,
              ),
              blurRadius: 10,
              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [
            // =================================
            // PAW ICON
            // =================================

            Container(
              height: 48,
              width: 48,

              decoration:
                  BoxDecoration(
                color: Colors.green
                    .withOpacity(
                  0.12,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: const Icon(
                Icons.pets,
                color: Colors.green,
                size: 25,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // =================================
            // DETAILS
            // =================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    dogName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color: WalkHistoryScreen
                          .navy,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    'Walker: $walkerName',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      color:
                          WalkHistoryScreen.slate,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    '$distance • $duration',
                    style:
                        const TextStyle(
                      color:
                          WalkHistoryScreen.slate,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    date,
                    style:
                        const TextStyle(
                      color:
                          WalkHistoryScreen.slate,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // =================================
            // STATUS + ARROW
            // =================================

            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.green
                        .withOpacity(
                      0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),

                  child: Text(
                    status
                        .toUpperCase(),
                    style:
                        const TextStyle(
                      color:
                          Colors.green,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Icon(
                  Icons
                      .arrow_forward_ios,
                  size: 13,
                  color:
                      Color(0xFF8A96A3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================
  // WALK DETAILS
  // ===============================================

  void _showWalkDetails(
    BuildContext context, {
    required String dogName,
    required String walkerName,
    required String distance,
    required String duration,
    required String date,
    required String status,
    required String walkId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,

      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),

          decoration:
              const BoxDecoration(
            color: Color(0xFFF7F8FA),
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color: const Color(
                      0xFFD0D5DB,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                'Walk Details',
                style: TextStyle(
                  color:
                      WalkHistoryScreen.navy,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              _detailRow(
                Icons.pets,
                'Dog',
                dogName,
              ),

              _detailRow(
                Icons.person_outline,
                'Walker',
                walkerName,
              ),

              _detailRow(
                Icons.route,
                'Distance',
                distance,
              ),

              _detailRow(
                Icons.timer_outlined,
                'Duration',
                duration,
              ),

              _detailRow(
                Icons.calendar_today_outlined,
                'Date',
                date,
              ),

              _detailRow(
                Icons.check_circle_outline,
                'Status',
                status,
              ),

              const SizedBox(
                height: 10,
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 13,
      ),

      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color:
                AppColors.primary,
          ),

          const SizedBox(
            width: 12,
          ),

          Text(
            '$title:',
            style:
                const TextStyle(
              color:
                  WalkHistoryScreen.slate,
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            width: 7,
          ),

          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                color:
                    WalkHistoryScreen.navy,
                fontSize: 12,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================
  // HELPERS
  // ===============================================

  static String _stringValue(
    dynamic value, {
    required String fallback,
  }) {
    if (value == null) {
      return fallback;
    }

    final String text =
        value.toString().trim();

    return text.isEmpty
        ? fallback
        : text;
  }

  static String _formatDistance(
    dynamic value,
  ) {
    if (value == null) {
      return '0 km';
    }

    if (value is num) {
      return '${value.toStringAsFixed(1)} km';
    }

    final double? parsed =
        double.tryParse(
      value.toString(),
    );

    if (parsed == null) {
      return '${value.toString()} km';
    }

    return '${parsed.toStringAsFixed(1)} km';
  }

  static String _formatDuration(
    dynamic value,
  ) {
    if (value == null) {
      return '0 mins';
    }

    if (value is num) {
      return '${value.toInt()} mins';
    }

    return '${value.toString()} mins';
  }

  static String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return 'Date unavailable';
    }

    if (value is Timestamp) {
      final DateTime date =
          value.toDate();

      return '${_twoDigits(date.day)} '
          '${_monthName(date.month)} '
          '${date.year}';
    }

    return value.toString();
  }

  static String _twoDigits(
    int value,
  ) {
    return value < 10
        ? '0$value'
        : value.toString();
  }

  static String _monthName(
    int month,
  ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    if (month < 1 ||
        month > 12) {
      return '';
    }

    return months[month - 1];
  }
}

// =====================================================
// EMPTY VIEW
// =====================================================

class _EmptyWalkView extends StatelessWidget {
  const _EmptyWalkView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),

      padding:
          const EdgeInsets.all(25),

      children: [
        const SizedBox(
          height: 80,
        ),

        Container(
          height: 80,
          width: 80,

          decoration:
              BoxDecoration(
            color: AppColors.primary
                .withOpacity(
              0.10,
            ),
            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.pets,
            size: 40,
            color:
                AppColors.primary,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        const Text(
          'No Walk History',
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                WalkHistoryScreen.navy,
            fontSize: 20,
            fontWeight:
                FontWeight.w900,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        const Text(
          'Your completed walks will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                WalkHistoryScreen.slate,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// =====================================================
// NOT LOGGED IN
// =====================================================

class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding:
            EdgeInsets.all(25),
        child: Text(
          'Please login to view your walk history.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                WalkHistoryScreen.slate,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ERROR
// =====================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(25),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.cloud_off,
              size: 45,
              color: Colors.grey,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    WalkHistoryScreen.slate,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            ElevatedButton(
              onPressed: onRetry,
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
