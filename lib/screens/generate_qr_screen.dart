"lib/screens/generate_qr_screen.dart"

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GenerateQRButton extends StatelessWidget {
  /// ==========================================================
  /// LIVE WALK STATE
  ///
  /// false = Generate QR Code
  /// true  = Live Walk bar
  /// ==========================================================
  final bool isLiveWalk;

  /// ==========================================================
  /// LIVE WALK TAP
  ///
  /// Existing navigation callback.
  /// ==========================================================
  final VoidCallback? onLiveWalkTap;

  const GenerateQRButton({
    super.key,
    this.isLiveWalk = false,
    this.onLiveWalkTap,
  });

  // ==========================================================
  // GET OWNER CURRENT LOCATION
  // ==========================================================
  //
  // IMPORTANT:
  //
  // This location is captured ONLY once while generating QR.
  //
  // It is a SAVED / DESTINATION location.
  //
  // It is NOT a live location stream.
  //
  // Walker will receive this saved location only.
  //
  // Owner's live location will NEVER be sent to Walker.
  // ==========================================================

  Future<Position?> _getOwnerLocation() async {
    try {
      // --------------------------------------------------------
      // LOCATION SERVICE
      // --------------------------------------------------------

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      // --------------------------------------------------------
      // PERMISSION
      // --------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // --------------------------------------------------------
      // CURRENT POSITION
      // --------------------------------------------------------
      //
      // Do NOT use locationSettings here.
      //
      // This keeps compatibility with the Geolocator version
      // currently used by the project.
      // --------------------------------------------------------

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint(
        'Owner location error: $e',
      );

      // Location failure must NOT stop QR generation.
      return null;
    }
  }

  // ==========================================================
  // GENERATE QR
  // ==========================================================

  Future<void> _generateQR(
    BuildContext context,
  ) async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Owner is not logged in.',
          ),
        ),
      );

      return;
    }

    // ========================================================
    // OWNER UID
    // ========================================================

    final String ownerUid =
        user.uid.trim();

    if (ownerUid.isEmpty) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Owner UID is missing.',
          ),
        ),
      );

      return;
    }

    // ========================================================
    // OWNER NAME
    // ========================================================

    final String ownerName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Owner';

    // ========================================================
    // OWNER PHONE
    // ========================================================

    final String ownerPhone =
        user.phoneNumber?.trim().isNotEmpty == true
            ? user.phoneNumber!.trim()
            : '';

    // ========================================================
    // WALK ID
    // ========================================================

    final String walkId =
        'WALK_${DateTime.now().millisecondsSinceEpoch}';

    // ========================================================
    // GET SAVED OWNER LOCATION
    // ========================================================
    //
    // This is captured once.
    //
    // No listener.
    // No stream.
    // No continuous update.
    //
    // Walker will only use this location as destination.
    // ========================================================

    final Position? ownerPosition =
        await _getOwnerLocation();

    // ========================================================
    // LOCATION DATA
    // ========================================================

    final Map<String, dynamic> ownerLocation =
        <String, dynamic>{};

    if (ownerPosition != null) {
      ownerLocation['latitude'] =
          ownerPosition.latitude;

      ownerLocation['longitude'] =
          ownerPosition.longitude;

      ownerLocation['accuracy'] =
          ownerPosition.accuracy;
    }

    // ========================================================
    // REAL QR DATA
    // ========================================================
    //
    // IMPORTANT:
    //
    // ownerLocation is a SNAPSHOT.
    //
    // It does not represent Owner LIVE location.
    // ========================================================

    final Map<String, dynamic> qrData =
        <String, dynamic>{
      'type': 'owner',

      'ownerUid':
          ownerUid,

      'ownerName':
          ownerName,

      'ownerPhone':
          ownerPhone,

      'walkId':
          walkId,

      // ------------------------------------------------------
      // SAVED OWNER DESTINATION
      // ------------------------------------------------------

      if (ownerPosition != null)
        'ownerLocation':
            ownerLocation,

      // ------------------------------------------------------
      // LOCATION TYPE
      // ------------------------------------------------------

      'ownerLocationType':
          'saved',

      // ------------------------------------------------------
      // WALK TRACKING STATE
      // ------------------------------------------------------

      'walkerTracking':
          false,

      'walkStarted':
          false,

      'walkEnded':
          false,
    };

    final String qrPayload =
        jsonEncode(qrData);

    // ========================================================
    // SAVE TO FIRESTORE
    // ========================================================

    try {
      await FirebaseFirestore.instance
          .collection('qr_codes')
          .doc(ownerUid)
          .set(
        <String, dynamic>{
          ...qrData,

          // --------------------------------------------------
          // COMPATIBILITY FIELDS
          // --------------------------------------------------

          'uid':
              ownerUid,

          'userId':
              ownerUid,

          'name':
              ownerName,

          'phoneNumber':
              ownerPhone,

          // --------------------------------------------------
          // QR PAYLOAD
          // --------------------------------------------------

          'qrData':
              qrPayload,

          // --------------------------------------------------
          // SCAN STATE
          // --------------------------------------------------

          'scanned':
              false,

          'scannedBy':
              null,

          'scannedAt':
              null,

          // --------------------------------------------------
          // TRACKING STATE
          // --------------------------------------------------

          'trackingStarted':
              false,

          'trackingEnded':
              false,

          // --------------------------------------------------
          // LOCATION SNAPSHOT TIMESTAMP
          // --------------------------------------------------

          if (ownerPosition != null)
            'ownerLocationSavedAt':
                FieldValue.serverTimestamp(),

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        'Owner QR saved successfully.',
      );

      if (ownerPosition != null) {
        debugPrint(
          'Saved owner location: '
          '${ownerPosition.latitude}, '
          '${ownerPosition.longitude}',
        );
      } else {
        debugPrint(
          'Owner location was not available. '
          'QR generated without location.',
        );
      }
    } catch (e) {
      // QR फिर भी दिखाई देगा।
      debugPrint(
        'Firebase QR save error: $e',
      );
    }

    if (!context.mounted) return;

    // ========================================================
    // OPEN QR BOTTOM SHEET
    // ========================================================

    await showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) {
        return OwnerQRBottomSheet(
          ownerUid:
              ownerUid,
          ownerName:
              ownerName,
          ownerPhone:
              ownerPhone,
          walkId:
              walkId,
          qrPayload:
              qrPayload,
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ========================================================
    // LIVE WALK
    // ========================================================

    if (isLiveWalk) {
      return _liveWalkBar(context);
    }

    // ========================================================
    // NORMAL QR BUTTON
    // ========================================================

    return FloatingActionButton.extended(
      backgroundColor:
          const Color(0xFFF4511E),

      foregroundColor:
          Colors.white,

      elevation: 8,

      onPressed: () =>
          _generateQR(context),

      icon: const Icon(
        Icons.qr_code_2,
        size: 25,
      ),

      label: const Text(
        'Generate QR Code',
        style: TextStyle(
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ==========================================================
  // LIVE WALK BAR
  // ==========================================================

  Widget _liveWalkBar(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
      ),

      child: SizedBox(
        width:
            double.infinity,

        height: 56,

        child: Material(
          color:
              Colors.transparent,

          child: InkWell(
            onTap:
                onLiveWalkTap,

            borderRadius:
                BorderRadius.circular(16),

            child: Ink(
              decoration:
                  BoxDecoration(
                gradient:
                    const LinearGradient(
                  begin:
                      Alignment.centerLeft,

                  end:
                      Alignment.centerRight,

                  colors: [
                    Color(0xFF1B8F4D),
                    Color(0xFF126B39),
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(16),

                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(
                      0xFF126B39,
                    ).withValues(
                      alpha: .22,
                    ),

                    blurRadius:
                        12,

                    offset:
                        const Offset(0, 5),
                  ),
                ],
              ),

              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                  ),

                  // ==================================================
                  // ICON
                  // ==================================================

                  Container(
                    width: 38,
                    height: 38,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white
                              .withValues(
                        alpha: .15,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),

                    child:
                        const Icon(
                      Icons
                          .directions_walk_rounded,

                      color:
                          Colors.white,

                      size: 21,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  // ==================================================
                  // TEXT
                  // ==================================================

                  const Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Live Walk',

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              TextStyle(
                            color:
                                Colors.white,

                            fontSize:
                                15,

                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),

                        SizedBox(
                          height: 1,
                        ),

                        Text(
                          'Tap to See',

                          maxLines: 1,

                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              TextStyle(
                            color:
                                Colors.white70,

                            fontSize:
                                10,

                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // ARROW
                  // ==================================================

                  Container(
                    width: 32,
                    height: 32,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.white
                              .withValues(
                        alpha: .10,
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        const Icon(
                      Icons
                          .arrow_forward_ios_rounded,

                      color:
                          Colors.white,

                      size: 14,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
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

// ================================================================
// OWNER QR BOTTOM SHEET
// ================================================================

class OwnerQRBottomSheet
    extends StatelessWidget {
  final String ownerUid;
  final String ownerName;
  final String ownerPhone;
  final String walkId;
  final String qrPayload;

  const OwnerQRBottomSheet({
    super.key,

    required this.ownerUid,

    required this.ownerName,

    required this.ownerPhone,

    required this.walkId,

    required this.qrPayload,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      child: Container(
        width:
            double.infinity,

        padding:
            const EdgeInsets.fromLTRB(
          24,
          12,
          24,
          30,
        ),

        decoration:
            const BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.vertical(
            top:
                Radius.circular(30),
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
              width: 45,
              height: 5,

              margin:
                  const EdgeInsets.only(
                bottom: 18,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xffd1d5db,
                ),

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
            ),

            // ==================================================
            // HEADER
            // ==================================================

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My QR Code',

                    textAlign:
                        TextAlign.center,

                    style:
                        TextStyle(
                      fontSize:
                          20,

                      fontWeight:
                          FontWeight.w800,

                      color:
                          Color(0xff111827),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  icon:
                      const Icon(
                    Icons.close,

                    color:
                        Color(0xff4b5563),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            // ==================================================
            // OWNER NAME
            // ==================================================

            Text(
              ownerName,

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                fontSize:
                    17,

                fontWeight:
                    FontWeight.w700,
              ),
            ),

            if (ownerPhone.isNotEmpty) ...[
              const SizedBox(
                height: 3,
              ),

              Text(
                ownerPhone,

                style:
                    const TextStyle(
                  fontSize:
                      13,

                  color:
                      Color(0xff6b7280),
                ),
              ),
            ],

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // REAL QR
            // ==================================================

            Container(
              width: 230,
              height: 230,

              padding:
                  const EdgeInsets.all(
                14,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                border:
                    Border.all(
                  color:
                      const Color(
                    0xffe5e7eb,
                  ),
                ),

                boxShadow:
                    const [
                  BoxShadow(
                    color:
                        Colors.black12,

                    blurRadius:
                        18,

                    offset:
                        Offset(0, 6),
                  ),
                ],
              ),

              child: QrImageView(
                data:
                    qrPayload,

                version:
                    QrVersions.auto,

                size:
                    200,

                backgroundColor:
                    Colors.white,

                errorCorrectionLevel:
                    QrErrorCorrectLevel.H,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // MESSAGE
            // ==================================================

            const Text(
              'Scan this QR code to connect with the Owner.',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                fontSize:
                    13,

                color:
                    Color(0xff6b7280),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // WAITING STATUS
            // ==================================================

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xfff0fdf4,
                ),

                borderRadius:
                    BorderRadius.circular(
                  30,
                ),
              ),

              child:
                  const Row(
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
                            Color(
                          0xff22c55e,
                        ),

                        shape:
                            BoxShape.circle,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 8,
                  ),

                  Text(
                    'Waiting for Walker to scan...',

                    style:
                        TextStyle(
                      fontSize:
                          12,

                      fontWeight:
                          FontWeight.w600,

                      color:
                          Color(0xff166534),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // WALK ID
            // ==================================================

            Text(
              'Walk ID: $walkId',

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontSize:
                    10,

                color:
                    Color(0xff9ca3af),
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            // ==================================================
            // UID
            // ==================================================

            Text(
              'Owner UID: ${ownerUid.substring(0, ownerUid.length > 8 ? 8 : ownerUid.length)}...',

              style:
                  const TextStyle(
                fontSize:
                    9,

                color:
                    Color(0xffd1d5db),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
