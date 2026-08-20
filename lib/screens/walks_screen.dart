import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import 'custom_app_bar.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color background = Color(0xFFEDEFF2);
  static const Color border = Color(0xFFD6DAE0);

  static const Color primary = AppColors.primary;
  static const Color callColor = Color(0xFF16A34A);
  static const Color smsColor = Color(0xFF238EAE);

  // ==========================================================
  // FIRESTORE
  // ==========================================================

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const CustomAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          15,
          18,
          15,
          110,
        ),
        children: [
          // ====================================================
          // PAGE TITLE
          // ====================================================

          Row(
            children: [
              Container(
                height: 21,
                width: 4,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Walks',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          const Text(
            'Find and manage your dog walks.',
            style: TextStyle(
              color: slate,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          // ====================================================
          // INSTA WALK
          // ====================================================

          _instaWalkCard(context),

          const SizedBox(height: 14),

          // ====================================================
          // ACTIVE WALKER
          // ====================================================

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('active_walk')
                .where(
                  'status',
                  isEqualTo: 'active',
                )
                .limit(1)
                .snapshots(),
            builder: (
              context,
              snapshot,
            ) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return _activeWalkerLoading();
              }

              if (snapshot.hasError) {
                return _activeWalkerError(
                  snapshot.error.toString(),
                );
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              final activeWalk =
                  snapshot.data!.docs.first.data();

              final String walkerId =
                  _stringValue(
                activeWalk['walkerId'],
              );

              if (walkerId.isEmpty) {
                return _activeWalkerError(
                  'Walker ID is missing.',
                );
              }

              return FutureBuilder<
                  DocumentSnapshot<Map<String, dynamic>>>(
                future: _findWalker(walkerId),
                builder: (
                  context,
                  walkerSnapshot,
                ) {
                  if (walkerSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _activeWalkerLoading();
                  }

                  if (walkerSnapshot.hasError) {
                    return _activeWalkerError(
                      walkerSnapshot.error.toString(),
                    );
                  }

                  final walkerData =
                      walkerSnapshot.data?.data() ?? {};

                  return _activeWalkerCard(
                    context,
                    activeWalk,
                    walkerData,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FIND WALKER
  // ==========================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      _findWalker(
    String walkerId,
  ) async {
    // First try document ID.
    final directDoc = await _firestore
        .collection('walkers')
        .doc(walkerId)
        .get();

    if (directDoc.exists) {
      return directDoc;
    }

    // Then try walkerId field.
    final query = await _firestore
        .collection('walkers')
        .where(
          'walkerId',
          isEqualTo: walkerId,
        )
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    return directDoc;
  }

  // ==========================================================
  // INSTA WALK CARD
  // ==========================================================

  Widget _instaWalkCard(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: .035,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primary.withValues(
                    alpha: .10,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insta Walk',
                      style: TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Find an available walker nearby.',
                      style: TextStyle(
                        color: slate,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton.icon(
              onPressed: () {
                // Existing Insta Walk flow.
              },
              icon: const Icon(
                Icons.search_rounded,
                size: 19,
              ),
              label: const Text(
                'Find a Walker',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIVE WALKER CARD
  // ==========================================================

  Widget _activeWalkerCard(
    BuildContext context,
    Map<String, dynamic> activeWalk,
    Map<String, dynamic> walkerData,
  ) {
    final String walkerId =
        _stringValue(
      activeWalk['walkerId'],
    );

    final String walkerName =
        _stringValue(
          activeWalk['walkerName'],
        ).isNotEmpty
            ? _stringValue(
                activeWalk['walkerName'],
              )
            : _stringValue(
                walkerData['Full Name'],
              ).isNotEmpty
                ? _stringValue(
                    walkerData['Full Name'],
                  )
                : 'Walker';

    final String ownerId =
        _stringValue(
      activeWalk['ownerId'],
    );

    final String phone =
        _walkerPhone(walkerData);

    final String petName =
        _stringValue(
      activeWalk['petName'],
    );

    final String distance =
        _stringValue(
      activeWalk['distance'],
    );

    final String duration =
        _stringValue(
      activeWalk['duration'],
    );

    final double? lat =
        _doubleValue(
      activeWalk['currentLat'],
    );

    final double? lng =
        _doubleValue(
      activeWalk['currentLng'],
    );

    return GestureDetector(
      onTap: () {
        _showWalkerDetails(
          context,
          activeWalk,
          walkerData,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: primary.withValues(
              alpha: .22,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: .04,
              ),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // =================================================
            // HEADER
            // =================================================

            Row(
              children: [
                _profileIcon(55),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WALKER ON THE WAY',
                        style: TextStyle(
                          color: primary,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        walkerName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: navy,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Walker ID: $walkerId',
                        style:
                            const TextStyle(
                          color: slate,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFEAF7EF),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: callColor,
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // =================================================
            // WALK SUMMARY
            // =================================================

            if (petName.isNotEmpty ||
                distance.isNotEmpty ||
                duration.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF7F8F9),
                  borderRadius:
                      BorderRadius.circular(13),
                  border: Border.all(
                    color: border,
                  ),
                ),
                child: Row(
                  children: [
                    if (petName.isNotEmpty)
                      Expanded(
                        child: _miniInfo(
                          Icons.pets_rounded,
                          petName,
                        ),
                      ),
                    if (distance.isNotEmpty)
                      Expanded(
                        child: _miniInfo(
                          Icons.route_rounded,
                          distance,
                        ),
                      ),
                    if (duration.isNotEmpty)
                      Expanded(
                        child: _miniInfo(
                          Icons.timer_outlined,
                          duration,
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // =================================================
            // ACTION BUTTONS
            // =================================================

            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon:
                        Icons.call_rounded,
                    label: 'Call',
                    color: callColor,
                    onTap: () {
                      _callWalker(phone);
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _actionButton(
                    icon:
                        Icons.sms_rounded,
                    label: 'SMS',
                    color: smsColor,
                    onTap: () {
                      _smsWalker(
                        phone: phone,
                        walkerId:
                            walkerId,
                        ownerId:
                            ownerId,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _actionButton(
                    icon:
                        Icons.location_on_rounded,
                    label: 'Track',
                    color: primary,
                    onTap: () {
                      _showTrackingMessage(
                        context,
                        lat,
                        lng,
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            const Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  Icons
                      .keyboard_arrow_up_rounded,
                  color: slate,
                  size: 17,
                ),
                SizedBox(width: 3),
                Text(
                  'Tap for walker details',
                  style: TextStyle(
                    color: slate,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MINI INFO
  // ==========================================================

  Widget _miniInfo(
    IconData icon,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: primary,
          size: 16,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: navy,
              fontSize: 10,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PROFILE ICON
  // ==========================================================

  Widget _profileIcon(
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withValues(
          alpha: .10,
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person_rounded,
        color: primary,
        size: size * .52,
      ),
    );
  }

  // ==========================================================
  // ACTION BUTTON
  // ==========================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 16,
          color: color,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          backgroundColor:
              color.withValues(
            alpha: .055,
          ),
          side: BorderSide(
            color:
                color.withValues(
              alpha: .18,
            ),
          ),
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LOADING
  // ==========================================================

  Widget _activeWalkerLoading() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Checking active walker...',
            style: TextStyle(
              color: slate,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _activeWalkerError(
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(
                color: slate,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WALKER DETAILS
  // ==========================================================

  void _showWalkerDetails(
    BuildContext context,
    Map<String, dynamic> activeWalk,
    Map<String, dynamic> walkerData,
  ) {
    final String walkerId =
        _stringValue(
      activeWalk['walkerId'],
    );

    final String walkerName =
        _stringValue(
          activeWalk['walkerName'],
        ).isNotEmpty
            ? _stringValue(
                activeWalk['walkerName'],
              )
            : _stringValue(
                walkerData['Full Name'],
              ).isNotEmpty
                ? _stringValue(
                    walkerData['Full Name'],
                  )
                : 'Walker';

    final String ownerId =
        _stringValue(
      activeWalk['ownerId'],
    );

    final String petName =
        _stringValue(
      activeWalk['petName'],
    );

    final String petBreed =
        _stringValue(
      activeWalk['petBreed'],
    );

    final String petAge =
        _stringValue(
      activeWalk['petAge'],
    );

    final String distance =
        _stringValue(
      activeWalk['distance'],
    );

    final String duration =
        _stringValue(
      activeWalk['duration'],
    );

    final double? lat =
        _doubleValue(
      activeWalk['currentLat'],
    );

    final double? lng =
        _doubleValue(
      activeWalk['currentLng'],
    );

    final String phone =
        _walkerPhone(walkerData);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(27),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFD4D8DC,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Row(
                      children: [
                        _profileIcon(64),

                        const SizedBox(
                          width: 13,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Walker on the way',
                                style:
                                    TextStyle(
                                  color:
                                      primary,
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                walkerName,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color: navy,
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                'Walker ID: $walkerId',
                                style:
                                    const TextStyle(
                                  color: slate,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFF7F8F9,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        border: Border.all(
                          color: border,
                        ),
                      ),
                      child: Column(
                        children: [
                          _detailRow(
                            Icons.pets_rounded,
                            'Pet',
                            petName.isNotEmpty
                                ? petName
                                : 'Not available',
                          ),

                          const Divider(
                            height: 20,
                          ),

                          _detailRow(
                            Icons.badge_outlined,
                            'Walker ID',
                            walkerId,
                          ),

                          const Divider(
                            height: 20,
                          ),

                          _detailRow(
                            Icons.person_outline,
                            'Owner ID',
                            ownerId.isNotEmpty
                                ? ownerId
                                : 'Not available',
                          ),

                          const Divider(
                            height: 20,
                          ),

                          _detailRow(
                            Icons.pets_outlined,
                            'Breed',
                            petBreed.isNotEmpty
                                ? petBreed
                                : 'Not available',
                          ),

                          const Divider(
                            height: 20,
                          ),

                          _detailRow(
                            Icons.cake_outlined,
                            'Pet Age',
                            petAge.isNotEmpty
                                ? petAge
                                : 'Not available',
                          ),

                          const Divider(
                            height: 20,
                          ),

                          _detailRow(
                            Icons
                                .directions_walk_rounded,
                            'Status',
                            'Walker on the way',
                            valueColor:
                                callColor,
                          ),

                          const Divider(
                            height: 20,
                          ),

                          _detailRow(
                            Icons.route_rounded,
                            'Distance',
                            distance.isNotEmpty
                                ? distance
                                : 'Not available',
                          ),

                          const Divider(
                            height: 20,
                          ),

                          _detailRow(
                            Icons.timer_outlined,
                            'Duration',
                            duration.isNotEmpty
                                ? duration
                                : 'Not started',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child:
                                OutlinedButton
                                    .icon(
                              onPressed: () {
                                _callWalker(
                                  phone,
                                );
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .call_rounded,
                                color:
                                    callColor,
                              ),
                              label:
                                  const Text(
                                'Call Walker',
                                style:
                                    TextStyle(
                                  color:
                                      callColor,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child:
                                OutlinedButton
                                    .icon(
                              onPressed: () {
                                _smsWalker(
                                  phone:
                                      phone,
                                  walkerId:
                                      walkerId,
                                  ownerId:
                                      ownerId,
                                );
                              },
                              icon:
                                  const Icon(
                                Icons
                                    .sms_rounded,
                                color:
                                    smsColor,
                              ),
                              label:
                                  const Text(
                                'SMS',
                                style:
                                    TextStyle(
                                  color:
                                      smsColor,
                                  fontWeight:
                                      FontWeight
                                          .w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child:
                          ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            sheetContext,
                          );

                          _showTrackingMessage(
                            context,
                            lat,
                            lng,
                          );
                        },
                        icon: const Icon(
                          Icons
                              .location_on_rounded,
                        ),
                        label: const Text(
                          'Track Walker',
                          style:
                              TextStyle(
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              primary,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Walker is on the way. The live walk has not started yet.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: slate,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value, {
    Color valueColor = navy,
  }) {
    return Row(
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: primary.withValues(
              alpha: .08,
            ),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 18,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: slate,
              fontSize: 11,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // WALKER PHONE
  // ==========================================================

  String _walkerPhone(
    Map<String, dynamic> walkerData,
  ) {
    const possibleFields = [
      'phone',
      'phoneNumber',
      'Mobile number',
      'mobile',
      'mobileNumber',
    ];

    for (final field in possibleFields) {
      final String value =
          _stringValue(
        walkerData[field],
      );

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  // ==========================================================
  // CALL WALKER
  // ==========================================================

  Future<void> _callWalker(
    String phone,
  ) async {
    if (phone.isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // SMS WALKER
  // ==========================================================

  Future<void> _smsWalker({
    required String phone,
    required String walkerId,
    required String ownerId,
  }) async {
    if (phone.isEmpty) {
      return;
    }

    final String message =
        'Dojo Walk\n'
        'Owner ID: $ownerId\n'
        'Walker ID: $walkerId\n'
        'Walk request from owner.';

    final Uri uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {
        'body': message,
      },
    );

    await launchUrl(uri);
  }

  // ==========================================================
  // TRACK
  // ==========================================================

  void _showTrackingMessage(
    BuildContext context,
    double? lat,
    double? lng,
  ) {
    final String message;

    if (lat != null && lng != null) {
      message =
          'Walker location: '
          '${lat.toStringAsFixed(5)}, '
          '${lng.toStringAsFixed(5)}';
    } else {
      message =
          'Walker location is not available yet.';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ==========================================================
  // STRING HELPER
  // ==========================================================

  static String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ==========================================================
  // DOUBLE HELPER
  // ==========================================================

  static double? _doubleValue(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value == null) {
      return null;
    }

    return double.tryParse(
      value.toString(),
    );
  }
}
