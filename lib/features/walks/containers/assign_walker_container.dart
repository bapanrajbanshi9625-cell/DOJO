import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models/assigned_walker.dart';
import '../services/assigned_walker_service.dart';
import '../services/walk_chat_service.dart';

class AssignWalkerContainer extends StatelessWidget {
  const AssignWalkerContainer({
    super.key,
  });

  static const Color navy =
      Color(0xFF263746);

  static const Color slate =
      Color(0xFF64748B);

  static const Color greenPrimary =
      Color(0xFF16803A);

  static const Color orangeSecondary =
      Color(0xFFE45D32);

  static const Color blackPrimary =
      Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AssignedWalker?>(
      stream:
          AssignedWalkerService.instance
              .assignedWalkerStream(),
      builder: (
        context,
        snapshot,
      ) {
        final AssignedWalker? walker =
            snapshot.data;

        if (walker == null) {
          return const SizedBox.shrink();
        }

        return _AssignedWalkerCard(
          walker: walker,
        );
      },
    );
  }
}

class _AssignedWalkerCard
    extends StatelessWidget {
  final AssignedWalker walker;

  const _AssignedWalkerCard({
    required this.walker,
  });

  static const Color navy =
      Color(0xFF263746);

  static const Color slate =
      Color(0xFF64748B);

  static const Color greenPrimary =
      Color(0xFF16803A);

  static const Color orangeSecondary =
      Color(0xFFE45D32);

  static const Color blackPrimary =
      Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD7DCE2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.06),
            blurRadius: 16,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // =========================================
          // HEADER
          // =========================================

          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color:
                      orangeSecondary
                          .withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons
                      .person_pin_circle_rounded,
                  color:
                      orangeSecondary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Walker',
                      style: TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Your walker has been assigned',
                      style: TextStyle(
                        color: slate,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                height: 27,
                width: 27,
                decoration:
                    BoxDecoration(
                  color:
                      greenPrimary
                          .withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color:
                      greenPrimary,
                  size: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          // =========================================
          // WALKER
          // =========================================

          Container(
            padding:
                const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color:
                    const Color(0xFFE0E4E9),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 53,
                  width: 53,
                  decoration:
                      BoxDecoration(
                    color:
                        orangeSecondary
                            .withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color:
                        orangeSecondary,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              walker.walkerName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                color: navy,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),
                          ),

                          if (walker.verified) ...[
                            const SizedBox(
                              width: 6,
                            ),
                            const Icon(
                              Icons
                                  .verified_rounded,
                              color:
                                  greenPrimary,
                              size: 17,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Walker UID: ${walker.walkerUid}',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color: slate,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        walker.verified
                            ? 'Verified Walker'
                            : 'Walker',
                        style:
                            const TextStyle(
                          color:
                              greenPrimary,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // =========================================
          // CALL + TRACK
          // =========================================

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon:
                      Icons.call_rounded,
                  label: 'Call',
                  background:
                      greenPrimary,
                  foreground:
                      Colors.white,
                  onTap: () {
                    _callWalker(
                      context,
                      walker,
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _ActionButton(
                  icon:
                      Icons.location_on_rounded,
                  label: 'Track',
                  background:
                      blackPrimary,
                  foreground:
                      Colors.white,
                  onTap: () {
                    _trackWalker(
                      context,
                      walker,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =========================================
          // CHAT + INTERACTION
          // =========================================

          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon:
                      Icons.chat_bubble_rounded,
                  label: 'Chat',
                  background:
                      orangeSecondary,
                  foreground:
                      Colors.white,
                  onTap: () {
                    _openChat(
                      context,
                      walker,
                    );
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _ActionButton(
                  icon:
                      Icons.mic_rounded,
                  label: 'Interaction',
                  background:
                      const Color(0xFFFFEEE8),
                  foreground:
                      orangeSecondary,
                  borderColor:
                      orangeSecondary
                          .withOpacity(.25),
                  onTap: () {
                    _openVoiceInteraction(
                      context,
                      walker,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // =========================================
          // STATUS
          // =========================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF0F7F2),
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color:
                    const Color(0xFFD5E9D9),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons
                      .directions_walk_rounded,
                  color:
                      greenPrimary,
                  size: 19,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Walker on the way',
                    style: TextStyle(
                      color:
                          greenPrimary,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'Active',
                  style: TextStyle(
                    color:
                        greenPrimary,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _ActionButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    Color? borderColor,
  }) {
    return SizedBox(
      height: 49,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          label,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              background,
          foregroundColor:
              foreground,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
            side: borderColor == null
                ? BorderSide.none
                : BorderSide(
                    color:
                        borderColor,
                  ),
          ),
        ),
      ),
    );
  }

  static void _callWalker(
    BuildContext context,
    AssignedWalker walker,
  ) {
    if (walker.walkerPhone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Walker phone number is unavailable.',
          ),
        ),
      );
      return;
    }

    // Phone launcher ko yahan add kar sakte ho.
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Calling ${walker.walkerName}...',
        ),
      ),
    );
  }

  static void _trackWalker(
    BuildContext context,
    AssignedWalker walker,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _WalkerTrackingScreen(
          walker: walker,
        ),
      ),
    );
  }

  static void _openChat(
    BuildContext context,
    AssignedWalker walker,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) =>
          _ChatSheet(
        walker: walker,
      ),
    );
  }

  static void _openVoiceInteraction(
    BuildContext context,
    AssignedWalker walker,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) =>
          _VoiceInteractionSheet(
        walker: walker,
      ),
    );
  }
}
