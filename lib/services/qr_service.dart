import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GenerateQRButton extends StatefulWidget {
  final bool isLiveWalk;

  final VoidCallback? onLiveWalkTap;

  // ==========================================================
  // QR CONNECTION CALLBACK
  //
  // Walker QR scan करके connect होते ही parent को notify करेगा.
  // Parent यहां से LiveWalkScreen खोल सकता है.
  // ==========================================================

  final void Function(QRScanState state)? onWalkerConnected;

  const GenerateQRButton({
    super.key,
    this.isLiveWalk = false,
    this.onLiveWalkTap,
    this.onWalkerConnected,
  });

  @override
  State<GenerateQRButton> createState() =>
      _GenerateQRButtonState();
}

class _GenerateQRButtonState
    extends State<GenerateQRButton> {
  StreamSubscription<QRScanState>?
      _scanSubscription;

  bool _opening = false;

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  // ==========================================================
  // OPEN QR
  // ==========================================================

  Future<void> _openQR() async {
    if (_opening) {
      return;
    }

    setState(() {
      _opening = true;
    });

    try {
      // ------------------------------------------------------
      // CREATE QR
      // ------------------------------------------------------

      final QRData? qr =
          await QRService.instance
              .createOwnerQR();

      if (!mounted || qr == null) {
        return;
      }

      // ------------------------------------------------------
      // CANCEL OLD LISTENER
      // ------------------------------------------------------

      await _scanSubscription?.cancel();

      // ------------------------------------------------------
      // WATCH WALKER SCAN
      // ------------------------------------------------------

      _scanSubscription =
          QRService.instance
              .watchScan(qr.ownerId)
              .listen(
        (QRScanState state) {
          if (!mounted) {
            return;
          }

          // -----------------------------------------------
          // WAITING
          // -----------------------------------------------

          if (!state.scanned &&
              !state.connected) {
            return;
          }

          // -----------------------------------------------
          // WALKER CONNECTED
          // -----------------------------------------------

          widget.onWalkerConnected?.call(state);
        },
      );

      // ------------------------------------------------------
      // OPEN QR BOTTOM SHEET
      // ------------------------------------------------------

      await showModalBottomSheet<void>(
        context: context,
        backgroundColor:
            Colors.transparent,
        isScrollControlled: true,
        isDismissible: true,
        enableDrag: true,
        builder: (_) {
          return QRBottomSheet(
            data: qr,
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // --------------------------------------------------------
    // LIVE WALK
    // --------------------------------------------------------

    if (widget.isLiveWalk) {
      return _liveWalkBar();
    }

    // --------------------------------------------------------
    // QR BUTTON
    // --------------------------------------------------------

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            _opening ? null : _openQR,
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          height: 58,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(
              begin:
                  Alignment.topLeft,
              end:
                  Alignment.bottomRight,
              colors: [
                Color(0xFFFF6A2A),
                Color(0xFFF4511E),
                Color(0xFFE83E0E),
              ],
            ),
            borderRadius:
                BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFF4511E,
                ).withValues(
                  alpha: .30,
                ),
                blurRadius: 18,
                offset:
                    const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              // ------------------------------------------------
              // ICON
              // ------------------------------------------------

              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: _opening
                    ? const Padding(
                        padding:
                            EdgeInsets.all(
                          11,
                        ),
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2.5,
                        ),
                      )
                    : const Icon(
                        Icons
                            .qr_code_scanner_rounded,
                        color:
                            Color(0xFFF4511E),
                        size: 25,
                      ),
              ),

              const SizedBox(
                width: 12,
              ),

              // ------------------------------------------------
              // TEXT
              // ------------------------------------------------

              const Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Show QR Code',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: TextStyle(
                        color:
                            Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Let your walker scan',
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style: TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------
              // ARROW
              // ------------------------------------------------

              Container(
                width: 31,
                height: 31,
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withValues(
                    alpha: .16,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .arrow_forward_ios_rounded,
                  color:
                      Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // LIVE WALK BAR
  // ==========================================================

  Widget _liveWalkBar() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                widget.onLiveWalkTap,
            borderRadius:
                BorderRadius.circular(16),
            child: Ink(
              decoration:
                  BoxDecoration(
                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFF1B8F4D),
                    Color(0xFF126B39),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                  ),
                  Icon(
                    Icons
                        .directions_walk_rounded,
                    color:
                        Colors.white,
                  ),
                  SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Text(
                      'Live Walk',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    color:
                        Colors.white,
                    size: 14,
                  ),
                  SizedBox(
                    width: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// QR BOTTOM SHEET
// ============================================================

class QRBottomSheet
    extends StatelessWidget {
  final QRData data;

  const QRBottomSheet({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.fromLTRB(
          22,
          10,
          22,
          26,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            // ==================================================
            // HANDLE
            // ==================================================

            Container(
              width: 44,
              height: 5,
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFD1D5DB,
                ),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // HEADER
            // ==================================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Scan to Connect',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 3,
            ),

            // ==================================================
            // NAME
            // ==================================================

            Text(
              data.ownerName,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            // ==================================================
            // REAL ID
            // ==================================================

            Text(
              'ID: ${data.ownerId}',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 11,
                color:
                    Color(0xFF64748B),
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // QR
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFFE5E7EB,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withValues(
                      alpha: .08,
                    ),
                    blurRadius: 20,
                    offset:
                        const Offset(
                      0,
                      7,
                    ),
                  ),
                ],
              ),
              child: QrImageView(
                data:
                    data.qrPayload,
                size: 215,
                version:
                    QrVersions.auto,
                backgroundColor:
                    Colors.white,
                errorCorrectionLevel:
                    QrErrorCorrectLevel.H,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // MESSAGE
            // ==================================================

            const Text(
              'Scan this QR with the Walker app',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    Color(0xFF64748B),
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // WAITING
            // ==================================================

            Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFF0FDF4,
                ),
                borderRadius:
                    BorderRadius.circular(
                  30,
                ),
              ),
              child: const Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child:
                        DecoratedBox(
                      decoration:
                          BoxDecoration(
                        color:
                            Color(0xFF22C55E),
                        shape:
                            BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    'Waiting for Walker...',
                    style:
                        TextStyle(
                      color:
                          Color(0xFF166534),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // WALK ID
            // ==================================================

            Text(
              'Walk ID: ${data.walkId}',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    Color(0xFF9CA3AF),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
