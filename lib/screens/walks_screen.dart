import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import 'custom_app_bar.dart';

class WalksScreen extends StatelessWidget {
  const WalksScreen({super.key});

  // ==========================================================
  // OWNER ROLE COLORS
  // ==========================================================

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF475569);
  static const Color background = Color(0xFFEDEFF2);
  static const Color border = Color(0xFFD6DAE0);

  // Role based colors
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
    // First try direct document ID.
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
            color: Colors.black.withOpacity(.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
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
                        fontWeight: FontWeight.w900,
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
                // Existing Insta Walk flow will be connected here.
              },
              icon: const Icon(
                Icons.search_rounded,
                size: 19,
              ),
              label: const Text(
                'Find a Walker',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIVE WALKER LOADING
  // ==========================================================

  Widget _activeWalkerLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Checking active walker...',
            style: TextStyle(
              color: slate,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTIVE WALKER ERROR
  // ==========================================================

  Widget _activeWalkerError(
    String message,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
              style: const TextStyle(
                color: slate,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
