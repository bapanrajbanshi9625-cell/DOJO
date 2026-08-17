import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/assigned_walker.dart';
import '../services/assigned_walker_service.dart';
import '../services/walk_request_service.dart';

class AssignWalkerContainer extends StatelessWidget {
  const AssignWalkerContainer({
    super.key,
  });

  static const Color navy = Color(0xFF263746);
  static const Color slate = Color(0xFF64748B);
  static const Color greenPrimary = Color(0xFF16803A);
  static const Color orangeSecondary = Color(0xFFE45D32);
  static const Color blackPrimary = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    // Firebase Auth UID is used ONLY to find
    // ownerProfiles/{authUid}.
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ownerProfiles')
          .doc(user.uid)
          .snapshots(),
      builder: (context, ownerSnapshot) {
        if (!ownerSnapshot.hasData) {
          return const SizedBox.shrink();
        }

        final ownerData =
            ownerSnapshot.data?.data();

        if (ownerData == null) {
          return const SizedBox.shrink();
        }

        final String ownerId =
            ownerData['ownerId']?.toString().trim() ?? '';

        if (ownerId.isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<AssignedWalker?>(
          stream: AssignedWalkerService
              .watchAssignedWalker(ownerId),
          builder: (context, snapshot) {
            final AssignedWalker? walker =
                snapshot.data;

            if (walker == null) {
              return const SizedBox.shrink();
            }

            return _buildContainer(
              context,
              walker,
            );
          },
        );
      },
    );
  }

  Widget _buildContainer(
    BuildContext context,
    AssignedWalker walker,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD7DCE2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color:
                      orangeSecondary.withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: orangeSecondary,
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
                      'Assigned Walker',
                      style: TextStyle(
                        color: navy,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
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
              if (walker.verified)
                Container(
                  height: 27,
                  width: 27,
                  decoration: BoxDecoration(
                    color:
                        greenPrimary.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: greenPrimary,
                    size: 17,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 17),

          // =====================================================
          // WALKER CARD
          // =====================================================

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFE0E4E9),
              ),
            ),
            child: Row(
              children: [
                // PROFILE IMAGE
                _walkerAvatar(walker),

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
                              walker.walkerName.isEmpty
                                  ? 'Walker'
                                  : walker.walkerName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                          if (walker.verified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified_rounded,
                              color: greenPrimary,
                              size: 17,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Walker ID: ${walker.walkerId}',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
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
                        style: const TextStyle(
                          color: greenPrimary,
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

          // =====================================================
          // CALL + TRACK
          // =====================================================

          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.call_rounded,
                  label: 'Call',
                  background: greenPrimary,
                  foreground: Colors.white,
                  onTap: () {
                    _showMessage(
                      context,
                      'Calling ${walker.walkerName}...',
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  icon: Icons.location_on_rounded,
                  label: 'Track',
                  background: blackPrimary,
                  foreground: Colors.white,
                  onTap: () {
                    _showMessage(
                      context,
                      'Opening live walker tracking...',
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // =====================================================
          // CHAT + VOICE
          // =====================================================

          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Chat',
                  background: orangeSecondary,
                  foreground: Colors.white,
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
                child: _actionButton(
                  icon: Icons.mic_rounded,
                  label: 'Interaction',
                  background:
                      const Color(0xFFFFEEE8),
                  foreground:
                      orangeSecondary,
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

          // =====================================================
          // STATUS
          // =====================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F2),
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: const Color(0xFFD5E9D9),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_walk_rounded,
                  color: greenPrimary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Walker on the way',
                    style: TextStyle(
                      color: greenPrimary,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  walker.status.isEmpty
                      ? 'Active'
                      : _formatStatus(
                          walker.status,
                        ),
                  style: const TextStyle(
                    color: greenPrimary,
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

  // =========================================================
  // WALKER AVATAR
  // =========================================================

  Widget _walkerAvatar(
    AssignedWalker walker,
  ) {
    final String image =
        walker.profileImage?.trim() ?? '';

    if (image.isEmpty) {
      return Container(
        height: 53,
        width: 53,
        decoration: BoxDecoration(
          color:
              orangeSecondary.withOpacity(.10),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          color: orangeSecondary,
          size: 28,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        image,
        height: 53,
        width: 53,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) {
          return Container(
            height: 53,
            width: 53,
            decoration: BoxDecoration(
              color: orangeSecondary
                  .withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: orangeSecondary,
              size: 28,
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // STATUS TEXT
  // =========================================================

  static String _formatStatus(
    String status,
  ) {
    final String value =
        status.trim();

    if (value.isEmpty) {
      return 'Active';
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  // =========================================================
  // ACTION BUTTON
  // =========================================================

  static Widget _actionButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CHAT
  // =========================================================

  static void _openChat(
    BuildContext context,
    AssignedWalker walker,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) => _ChatSheet(
        walker: walker,
      ),
    );
  }

  // =========================================================
  // VOICE
  // =========================================================

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
          const _VoiceInteractionSheet(),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  static void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}

// =============================================================
// CHAT SHEET
// =============================================================

class _ChatSheet extends StatefulWidget {
  final AssignedWalker walker;

  const _ChatSheet({
    required this.walker,
  });

  @override
  State<_ChatSheet> createState() =>
      _ChatSheetState();
}

class _ChatSheetState
    extends State<_ChatSheet> {
  final TextEditingController
      _controller =
      TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text =
        _controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      // Auth UID is NOT sent as owner ID.
      // First get ownerId from ownerProfiles.
      final ownerSnapshot =
          await FirebaseFirestore.instance
              .collection('ownerProfiles')
              .doc(user.uid)
              .get();

      final ownerData =
          ownerSnapshot.data();

      final String ownerId =
          ownerData?['ownerId']
                  ?.toString()
                  .trim() ??
              '';

      if (ownerId.isEmpty) {
        throw Exception(
          'Owner ID not found',
        );
      }

      await WalkRequestService.sendMessage(
        requestId:
            widget.walker.walkId,
        ownerId: ownerId,
        walkerId:
            widget.walker.walkerId,
        message: text,
      );

      if (!mounted) {
        return;
      }

      _controller.clear();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to send message. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      padding:
          const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18,
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
        children: [
          Container(
            width: 42,
            height: 4,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFD0D5DB),
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Chat with ${widget.walker.walkerName}',
                  style:
                      const TextStyle(
                    color:
                        AssignWalkerContainer
                            .navy,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                ),
                icon: const Icon(
                  Icons.close_rounded,
                ),
              ),
            ],
          ),

          const Expanded(
            child: Center(
              child: Text(
                'No messages yet',
                style: TextStyle(
                  color:
                      AssignWalkerContainer
                          .slate,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      _controller,
                  textInputAction:
                      TextInputAction.send,
                  onSubmitted:
                      (_) => _send(),
                  decoration:
                      InputDecoration(
                    hintText:
                        'Type a message...',
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        14,
                      ),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              SizedBox(
                height: 50,
                width: 50,
                child: ElevatedButton(
                  onPressed: _send,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AssignWalkerContainer
                            .orangeSecondary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    padding:
                        EdgeInsets.zero,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// VOICE INTERACTION
// =============================================================

class _VoiceInteractionSheet
    extends StatefulWidget {
  const _VoiceInteractionSheet();

  @override
  State<_VoiceInteractionSheet>
      createState() =>
          _VoiceInteractionSheetState();
}

class _VoiceInteractionSheetState
    extends State<_VoiceInteractionSheet> {
  bool recording = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24,
      ),
      decoration:
          const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Voice Interaction',
                    style: TextStyle(
                      color:
                          AssignWalkerContainer
                              .navy,
                      fontSize: 19,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Navigator.pop(
                    context,
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Text(
              recording
                  ? 'Recording your voice...'
                  : 'Talk to your walker',
              style:
                  const TextStyle(
                color:
                    AssignWalkerContainer
                        .slate,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 22),

            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 250,
              ),
              height:
                  recording ? 112 : 100,
              width:
                  recording ? 112 : 100,
              decoration:
                  BoxDecoration(
                color: recording
                    ? const Color(
                        0xFFFFE5DD,
                      )
                    : const Color(
                        0xFFFFEEE8,
                      ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                recording
                    ? Icons
                        .graphic_eq_rounded
                    : Icons.mic_rounded,
                color:
                    AssignWalkerContainer
                        .orangeSecondary,
                size: 45,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 51,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    recording =
                        !recording;
                  });
                },
                icon: Icon(
                  recording
                      ? Icons.send_rounded
                      : Icons.mic_rounded,
                ),
                label: Text(
                  recording
                      ? 'Send'
                      : 'Start Recording',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AssignWalkerContainer
                          .orangeSecondary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 9),

            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
              ),
              child:
                  const Text(
                'Cancel',
                style:
                    TextStyle(
                  color:
                      AssignWalkerContainer
                          .slate,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
