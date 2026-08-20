// File location: lib/screens/home_screen.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'custom_app_bar.dart';
import 'generate_qr_screen.dart';
import 'live_walk_screen.dart';

import '../features/home/services/home_data_service.dart'
    as home_data;
import '../features/home/services/home_live_walk_service.dart';

import '../features/home/widgets/home_live_walk_bar.dart';
import '../features/home/widgets/home_past_walk.dart';
import '../features/home/widgets/home_section_title.dart';
import '../features/home/widgets/home_weekly_processing.dart';
import '../features/home/widgets/home_welcome_card.dart';

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
  // HOME DATA SERVICE
  // =====================================================

  final home_data.HomeDataService _homeDataService =
      home_data.HomeDataService.instance;

  // =====================================================
  // LIVE WALK SERVICE
  // =====================================================

  final HomeLiveWalkService _liveWalkService =
      HomeLiveWalkService.instance;

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
  // OPEN LIVE WALK
  // =====================================================

  void _openLiveWalk(
    Map<String, dynamic> data,
  ) {
    if (!mounted) return;

    final String walkId =
        _readString(
          data,
          const [
            'walkId',
            'walkID',
            'id',
          ],
        );

    final String walkerUid =
        _readString(
          data,
          const [
            'walkerUid',
            'walkerUID',
            'walkerId',
          ],
        );

    final String walkerName =
        _readString(
          data,
          const [
            'walkerName',
            'name',
          ],
        );

    final String walkerPhone =
        _readString(
          data,
          const [
            'walkerPhone',
            'phone',
            'phoneNumber',
          ],
        );

    if (walkId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Live Walk information is not ready yet.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWalkScreen(
          walkId: walkId,
          walkerUid: walkerUid,
          walkerName:
              walkerName.isEmpty
                  ? 'Walker'
                  : walkerName,
          walkerPhone:
              walkerPhone.isEmpty
                  ? null
                  : walkerPhone,
        ),
      ),
    );
  }

  // =====================================================
  // STRING READER
  // =====================================================

  String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null) {
        final result =
            value.toString().trim();

        if (result.isNotEmpty) {
          return result;
        }
      }
    }

    return '';
  }

  // =====================================================
  // DETAILS DIALOG
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
              const Color(0xFFF7F8FA),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: HomeScreen.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              color: HomeScreen.slate,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),
              child: const Text(
                'CLOSE',
                style: TextStyle(
                  color: HomeScreen.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // CONVERT DATA MODEL → UI MAP
  // =====================================================
  //
  // IMPORTANT:
  //
  // home_data.HomePastWalk
  //     = Firestore/data model
  //
  // HomePastWalk
  //     = UI widget
  //
  // दोनों का नाम same है इसलिए service को
  // "home_data" alias दिया गया है.
  // =====================================================

  List<Map<String, dynamic>> _pastWalkMaps(
    List<home_data.HomePastWalk> walks,
  ) {
    return walks.map(
      (walk) {
        return <String, dynamic>{
          'walkId': walk.walkId,
          'id': walk.walkId,
          'ownerUid': walk.ownerUid,
          'walkerUid': walk.walkerUid,
          'walkerName': walk.walkerName,
          'dogName': walk.dogName,
          'distanceKm': walk.distanceKm,
          'durationMinutes':
              walk.durationMinutes,
          'date': walk.date,
          'status': walk.status,
          'route': walk.route,
        };
      },
    ).toList();
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

      body: SingleChildScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.fromLTRB(
          15,
          15,
          15,
          105,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // =========================================
            // WELCOME
            // =========================================

            const HomeWelcomeCard(),

            // =========================================
            // LIVE WALK
            // =========================================

            const SizedBox(height: 14),

            StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  _liveWalkService
                      .liveWalkStream(),

              builder:
                  (context, snapshot) {
                if (snapshot.hasError) {
                  return const SizedBox.shrink();
                }

                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final liveWalkData =
                    _liveWalkService
                        .getLiveWalkData(
                  snapshot.data!,
                );

                if (liveWalkData == null) {
                  return const SizedBox.shrink();
                }

                return HomeLiveWalkBar(
                  onTap: () {
                    _openLiveWalk(
                      liveWalkData,
                    );
                  },
                );
              },
            ),

            // =========================================
            // WEEKLY PROCESSING
            // =========================================

            const SizedBox(height: 19),

            const HomeSectionTitle(
              title: 'This week processing',
            ),

            const SizedBox(height: 9),

            HomeWeeklyProcessing(
              onDetails: (
                title,
                content,
              ) {
                _showDialog(
                  context,
                  title,
                  content,
                );
              },
            ),

            // =========================================
            // PAST WALK
            // =========================================

            const SizedBox(height: 19),

            const HomeSectionTitle(
              title: 'Past Walk',
            ),

            const SizedBox(height: 9),

            StreamBuilder<
                List<home_data.HomePastWalk>>(
              stream:
                  _homeDataService
                      .pastWalksStream(
                limit: 20,
              ),

              builder:
                  (context, snapshot) {
                // -------------------------------------
                // ERROR
                // -------------------------------------

                if (snapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(18),
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
                    ),
                    child:
                        const Text(
                      'Unable to load past walks.',
                      textAlign:
                          TextAlign.center,
                      style:
                          TextStyle(
                        color:
                            HomeScreen.slate,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  );
                }

                // -------------------------------------
                // LOADING
                // -------------------------------------

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 70,
                    child:
                        Center(
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            HomeScreen.orange,
                      ),
                    ),
                  );
                }

                // -------------------------------------
                // DATA
                // -------------------------------------

                final List<
                    home_data.HomePastWalk> walks =
                    snapshot.data ??
                        <home_data.HomePastWalk>[];

                // -------------------------------------
                // UI WIDGET
                // -------------------------------------

                return HomePastWalk(
                  walks:
                      _pastWalkMaps(
                    walks,
                  ),
                  onDetails: (
                    title,
                    content,
                  ) {
                    _showDialog(
                      context,
                      title,
                      content,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),

      // ===============================================
      // BOTTOM BUTTON
      // ===============================================

      floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerFloat,

      floatingActionButton:
          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
        stream:
            _liveWalkService
                .liveWalkStream(),

        builder:
            (context, snapshot) {
          final bool live =
              snapshot.hasData &&
              _liveWalkService
                  .isLiveWalk(
                snapshot.data!,
              );

          // =========================================
          // LIVE WALK
          // QR BUTTON HIDDEN
          // =========================================

          if (live) {
            return const SizedBox.shrink();
          }

          // =========================================
          // NORMAL
          // QR BUTTON
          // =========================================

          return FloatingActionButton.extended(
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
          );
        },
      ),
    );
  }
}
