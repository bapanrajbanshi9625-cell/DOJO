// File location: lib/screens/home_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'custom_app_bar.dart';
import 'generate_qr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const orange = Color(0xFFF4511E);
  static const navy = Color(0xFF263746);
  static const slate = Color(0xFF475569);
  static const background = Color(0xFFEDEFF2);
  static const card = Color(0xFFF7F8FA);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
  }

  // =====================================================
  // GENERATE OWNER QR
  // =====================================================

  Future<void> _openMyQRCode() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login first.',
          ),
        ),
      );

      return;
    }

    final String ownerUid =
        user.uid.trim();

    if (ownerUid.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Owner UID is missing.',
          ),
        ),
      );

      return;
    }

    final String ownerName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Owner';

    final String ownerPhone =
        user.phoneNumber?.trim().isNotEmpty == true
            ? user.phoneNumber!.trim()
            : '';

    final String walkId =
        'WALK_${DateTime.now().millisecondsSinceEpoch}';

    final Map<String, dynamic> qrData = {
      'type': 'owner',
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'walkId': walkId,

      // Compatibility fields
      'uid': ownerUid,
      'userId': ownerUid,
      'name': ownerName,
      'phoneNumber': ownerPhone,
    };

    final String qrPayload =
        jsonEncode(qrData);

    try {
      await FirebaseFirestore.instance
          .collection('qr_codes')
          .doc(ownerUid)
          .set(
        {
          'type': 'owner',
          'ownerUid': ownerUid,
          'ownerName': ownerName,
          'ownerPhone': ownerPhone,
          'uid': ownerUid,
          'userId': ownerUid,
          'name': ownerName,
          'phoneNumber': ownerPhone,
          'walkId': walkId,
          'qrData': qrPayload,
          'scanned': false,
          'scannedBy': null,
          'scannedAt': null,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        'Owner QR saved successfully: $ownerUid',
      );
    } catch (e) {
      debugPrint(
        'Owner QR Firebase save failed: $e',
      );
    }

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) {
        return OwnerQRBottomSheet(
          ownerUid: ownerUid,
          ownerName: ownerName,
          ownerPhone: ownerPhone,
          walkId: walkId,
          qrPayload: qrPayload,
        );
      },
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          HomeScreen.background,

      appBar:
          const CustomAppBar(),

      body:
          SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          15,
          15,
          15,
          105,
        ),

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // =========================================
            // WELCOME HEADER
            // =========================================

            Container(
              width:
                  double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 14,
              ),

              decoration:
                  BoxDecoration(
                gradient:
                    const LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                  colors: [
                    Color(0xFF34495E),
                    Color(0xFF263746),
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(
                      0.10,
                    ),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 5),
                  ),
                ],
              ),

              child:
                  Row(
                children: [

                  Container(
                    height: 46,
                    width: 46,

                    decoration:
                        BoxDecoration(
                      color:
                          HomeScreen.orange
                              .withOpacity(
                        0.16,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),

                      border:
                          Border.all(
                        color:
                            HomeScreen.orange
                                .withOpacity(
                          0.40,
                        ),
                      ),
                    ),

                    child:
                        const Icon(
                      Icons.pets,
                      color:
                          HomeScreen.orange,
                      size: 24,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  const Expanded(
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [

                        Text(
                          'Welcome back 👋',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              TextStyle(
                            color:
                                Colors.white,
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        SizedBox(
                          height: 3,
                        ),

                        Text(
                          'Your walking activity is on track.',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =========================================
            // LIVE WALK
            //
            // REMOVED FROM HOME SCREEN
            //
            // Live Walk will now be shown inside
            // Walks Screen below Insta Walk.
            // =========================================

            // =========================================
            // WEEKLY PROCESSING
            // =========================================

            const SizedBox(
              height: 19,
            ),

            _sectionTitle(
              'This week processing',
            ),

            const SizedBox(
              height: 9,
            ),

            Container(
              padding:
                  const EdgeInsets.all(
                13,
              ),

              decoration:
                  BoxDecoration(
                color:
                    HomeScreen.card,

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),

                border:
                    Border.all(
                  color:
                      const Color(
                    0xFFD6DAE0,
                  ),
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withOpacity(
                      0.055,
                    ),

                    blurRadius: 11,

                    offset:
                        const Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),

              child:
                  Column(
                children: [

                  Row(
                    children: [

                      Expanded(
                        child:
                            _statCard(
                          context,

                          title:
                              'Total Walks',

                          value:
                              '12',

                          icon:
                              Icons.pets,

                          iconColor:
                              HomeScreen
                                  .orange,

                          details:
                              'Completed Walks: 12\n'
                              'Average Walks/Day: 1.5\n'
                              'Status: On Track',
                        ),
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child:
                            _statCard(
                          context,

                          title:
                              'Distance',

                          value:
                              '24.5',

                          suffix:
                              ' km',

                          icon:
                              Icons.route,

                          iconColor:
                              const Color(
                            0xFF2196F3,
                          ),

                          details:
                              'Total Distance: 24.5 km\n'
                              'Average per Walk: 2.04 km\n'
                              'Longest Walk: 3.5 km',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 9,
                  ),

                  Row(
                    children: [

                      Expanded(
                        child:
                            _durationCard(
                          context,
                        ),
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      Expanded(
                        child:
                            _reportCard(
                          context,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =========================================
            // PAST WALK
            // =========================================

            const SizedBox(
              height: 19,
            ),

            _sectionTitle(
              'Past Walk',
            ),

            const SizedBox(
              height: 9,
            ),

            _walkCard(
              context,

              id:
                  '#WID-9842',

              time:
                  '08:30 AM',

              date:
                  '04 Aug 2026',

              distance:
                  '2.1 km',

              duration:
                  '30 mins',
            ),

            const SizedBox(
              height: 8,
            ),

            _walkCard(
              context,

              id:
                  '#WID-9817',

              time:
                  '07:15 AM',

              date:
                  '03 Aug 2026',

              distance:
                  '1.8 km',

              duration:
                  '27 mins',
            ),
          ],
        ),
      ),

      // ===============================================
      // GENERATE QR CODE
      // ===============================================

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerFloat,

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            HomeScreen.orange,

        foregroundColor:
            Colors.white,

        elevation: 8,

        onPressed:
            _openMyQRCode,

        icon:
            const Icon(
          Icons.qr_code_2,
        ),

        label:
            const Text(
          'Generate QR Code',

          style:
              TextStyle(
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // SECTION TITLE
  // =====================================================

  Widget _sectionTitle(
    String title,
  ) {
    return Row(
      children: [

        Container(
          height: 19,
          width: 4,

          decoration:
              BoxDecoration(
            color:
                HomeScreen.orange,

            borderRadius:
                BorderRadius.circular(
              5,
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          title,

          style:
              const TextStyle(
            color:
                HomeScreen.navy,

            fontSize: 16,

            fontWeight:
                FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // STAT CARD
  // =====================================================

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    String suffix = '',
    required IconData icon,
    required Color iconColor,
    required String details,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        14,
      ),

      onTap: () {
        _showDialog(
          context,
          '$title Details',
          details,
        );
      },

      child:
          Container(
        constraints:
            const BoxConstraints(
          minHeight: 88,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 12,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFEFF2F5,
          ),

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xFFD4D9DF,
            ),
          ),
        ),

        child:
            Row(
          children: [

            Container(
              height: 43,
              width: 43,

              decoration:
                  BoxDecoration(
                color:
                    iconColor
                        .withOpacity(
                  0.12,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child:
                  Icon(
                icon,
                color:
                    iconColor,
                size: 22,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    title,

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      color:
                          HomeScreen.slate,

                      fontSize: 11,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  FittedBox(
                    fit:
                        BoxFit.scaleDown,

                    alignment:
                        Alignment
                            .centerLeft,

                    child:
                        RichText(
                      text:
                          TextSpan(
                        children: [

                          TextSpan(
                            text:
                                value,

                            style:
                                const TextStyle(
                              color:
                                  HomeScreen.navy,

                              fontSize: 20,

                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          if (suffix
                              .isNotEmpty)
                            TextSpan(
                              text:
                                  suffix,

                              style:
                                  TextStyle(
                                color:
                                    iconColor,

                                fontSize:
                                    10,

                                fontWeight:
                                    FontWeight
                                        .w900,
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

  // =====================================================
  // DURATION CARD
  // =====================================================

  Widget _durationCard(
    BuildContext context,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        14,
      ),

      onTap: () {
        _showDialog(
          context,
          'Duration Details',
          'Total Active Time: 6 hours\n'
          'Average Duration per Walk: 30 minutes\n'
          'Pace Efficiency: Good',
        );
      },

      child:
          Container(
        constraints:
            const BoxConstraints(
          minHeight: 88,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 12,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFEFF2F5,
          ),

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xFFD4D9DF,
            ),
          ),
        ),

        child:
            Row(
          children: [

            Container(
              height: 43,
              width: 43,

              decoration:
                  BoxDecoration(
                color:
                    Colors.green
                        .withOpacity(
                  0.12,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child:
                  const Icon(
                Icons.timer_outlined,
                color:
                    Colors.green,
                size: 22,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            const Expanded(
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    'Active Duration',

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        TextStyle(
                      color:
                          HomeScreen.slate,

                      fontSize: 11,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  SizedBox(
                    height: 3,
                  ),

                  FittedBox(
                    fit:
                        BoxFit.scaleDown,

                    alignment:
                        Alignment
                            .centerLeft,

                    child:
                        Text(
                      '6 hrs',

                      style:
                          TextStyle(
                        color:
                            HomeScreen.navy,

                        fontSize: 20,

                        fontWeight:
                            FontWeight.w900,
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

  // =====================================================
  // REPORT CARD
  // =====================================================

  Widget _reportCard(
    BuildContext context,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        14,
      ),

      onTap: () {
        _showDialog(
          context,
          'Report Card',
          'First Week Report: Completed (10 Walks)\n\n'
          'Current Week Report: Active (12 Walks)\n\n'
          'Current Week Start: 03 Aug 2026',
        );
      },

      child:
          Container(
        constraints:
            const BoxConstraints(
          minHeight: 88,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 12,
        ),

        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFFFF1EA,
          ),

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border:
              Border.all(
            color:
                HomeScreen.orange
                    .withOpacity(
              0.25,
            ),
          ),
        ),

        child:
            Row(
          children: [

            Container(
              height: 43,
              width: 43,

              decoration:
                  BoxDecoration(
                color:
                    HomeScreen.orange,

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child:
                  const Icon(
                Icons.assessment_outlined,
                color:
                    Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            const Expanded(
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,

                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    'Report Card',

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        TextStyle(
                      color:
                          HomeScreen.slate,

                      fontSize: 11,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  SizedBox(
                    height: 3,
                  ),

                  FittedBox(
                    fit:
                        BoxFit.scaleDown,

                    alignment:
                        Alignment
                            .centerLeft,

                    child:
                        Text(
                      'Performance',

                      style:
                          TextStyle(
                        color:
                            HomeScreen.navy,

                        fontSize: 17,

                        fontWeight:
                            FontWeight.w900,
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

  // =====================================================
  // PAST WALK CARD
  // =====================================================

  Widget _walkCard(
    BuildContext context, {
    required String id,
    required String time,
    required String date,
    required String distance,
    required String duration,
  }) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(
        14,
      ),

      onTap: () {
        _showDialog(
          context,
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

      child:
          Container(
        padding:
            const EdgeInsets.all(
          11,
        ),

        decoration:
            BoxDecoration(
          color:
              HomeScreen.card,

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          border:
              Border.all(
            color:
                const Color(
              0xFFD4D9DF,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black
                      .withOpacity(
                0.045,
              ),

              blurRadius: 8,

              offset:
                  const Offset(
                0,
                3,
              ),
            ),
          ],
        ),

        child:
            Row(
          children: [

            Container(
              height: 42,
              width: 42,

              decoration:
                  BoxDecoration(
                color:
                    Colors.green
                        .withOpacity(
                  0.12,
                ),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child:
                  const Icon(
                Icons.pets,
                color:
                    Colors.green,
                size: 21,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [

                  Text(
                    '$id • $time',

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      color:
                          HomeScreen.navy,

                      fontWeight:
                          FontWeight.w900,

                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    '$distance • $duration • $date',

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    style:
                        const TextStyle(
                      color:
                          HomeScreen.slate,

                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 7,
                vertical: 4,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.green
                        .withOpacity(
                  0.10,
                ),

                borderRadius:
                    BorderRadius.circular(
                  7,
                ),
              ),

              child:
                  const Text(
                'DONE',

                style:
                    TextStyle(
                  color:
                      Colors.green,

                  fontSize: 8,

                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color:
                  Color(
                0xFF8A96A3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DIALOG
  // =====================================================

  void _showDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    showDialog(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              const Color(
            0xFFF7F8FA,
          ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
          ),

          title:
              Text(
            title,

            style:
                const TextStyle(
              color:
                  HomeScreen.navy,

              fontWeight:
                  FontWeight.w900,
            ),
          ),

          content:
              Text(
            content,

            style:
                const TextStyle(
              color:
                  HomeScreen.slate,

              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed:
                  () =>
                      Navigator.pop(
                ctx,
              ),

              child:
                  const Text(
                'CLOSE',

                style:
                    TextStyle(
                  color:
                      HomeScreen.orange,

                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
