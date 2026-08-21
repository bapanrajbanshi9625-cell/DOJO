import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../screens/address_screen.dart';

class InstaWalkContainer extends StatefulWidget {
  final VoidCallback? onWalkerFound;

  const InstaWalkContainer({
    super.key,
    this.onWalkerFound,
  });

  @override
  State<InstaWalkContainer> createState() =>
      _InstaWalkContainerState();
}

class _InstaWalkContainerState
    extends State<InstaWalkContainer>
    with SingleTickerProviderStateMixin {
  // =========================================================
  // FIREBASE
  // =========================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _ownerProfilesCollection =
      'ownerProfiles';

  static const String _walkRequestsCollection =
      'walk_requests';

  // =========================================================
  // SEARCH SETTINGS
  // =========================================================

  static const double _searchDistanceKm = 3.0;

  static const int _searchDurationSeconds = 120;

  // =========================================================
  // STATE
  // =========================================================

  Timer? _timer;

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  bool _searching = false;
  bool _searchFinished = false;
  bool _checkingAddress = false;

  int _secondsLeft = _searchDurationSeconds;

  String? _requestId;

  Position? _ownerPosition;

  // =========================================================
  // RADAR ANIMATION
  // =========================================================

  late final AnimationController _radarController;

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _timer?.cancel();
    _requestSubscription?.cancel();
    _radarController.dispose();

    super.dispose();
  }

  // =========================================================
  // FIND OWNER PROFILE
  // =========================================================

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      _findOwnerProfile() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final QuerySnapshot<
        Map<String, dynamic>> query =
        await _firestore
            .collection(
              _ownerProfilesCollection,
            )
            .where(
              'authUid',
              isEqualTo: user.uid,
            )
            .limit(1)
            .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first;
  }

  // =========================================================
  // GET OWNER CURRENT LOCATION
  // =========================================================

  Future<Position?> _getOwnerLocation() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please turn on location service.',
        );

        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission
                  .deniedForever) {
        _showMessage(
          'Location permission is required for Insta Walk.',
        );

        return null;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      return position;
    } catch (e) {
      debugPrint(
        'Insta Walk location error: $e',
      );

      _showMessage(
        'Unable to get your current location.',
      );

      return null;
    }
  }

  // =========================================================
  // FIND WALKER
  // =========================================================

  Future<void> _findWalker() async {
    if (_searching || _checkingAddress) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _checkingAddress = true;
      _searchFinished = false;
    });

    try {
      // =====================================================
      // OWNER PROFILE
      // =====================================================

      final QueryDocumentSnapshot<
          Map<String, dynamic>>? ownerDoc =
          await _findOwnerProfile();

      if (!mounted) {
        return;
      }

      if (ownerDoc == null) {
        setState(() {
          _checkingAddress = false;
        });

        _showMessage(
          'Owner profile not found. Please complete your profile.',
        );

        return;
      }

      final Map<String, dynamic> ownerData =
          ownerDoc.data();

      // =====================================================
      // OWNER ID
      // =====================================================

      final String ownerId =
          ownerData['ownerId']
                  ?.toString()
                  .trim() ??
              '';

      if (ownerId.isEmpty) {
        setState(() {
          _checkingAddress = false;
        });

        _showMessage(
          'Owner ID not found. Please complete your owner profile.',
        );

        return;
      }

      // =====================================================
      // ADDRESS
      // =====================================================

      String address =
          ownerData['address']
                  ?.toString()
                  .trim() ??
              '';

      if (address.isEmpty) {
        address =
            ownerData['Adress']
                    ?.toString()
                    .trim() ??
                '';
      }

      // =====================================================
      // ADDRESS EMPTY
      // =====================================================

      if (address.isEmpty) {
        setState(() {
          _checkingAddress = false;
        });

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AddressScreen(),
          ),
        );

        if (!mounted) {
          return;
        }

        await _findWalker();

        return;
      }

      // =====================================================
      // OWNER NAME
      // =====================================================

      String ownerName =
          ownerData['fullName']
                  ?.toString()
                  .trim() ??
              '';

      if (ownerName.isEmpty) {
        ownerName =
            ownerData['Full Name']
                    ?.toString()
                    .trim() ??
                '';
      }

      if (ownerName.isEmpty) {
        ownerName = 'Dog Owner';
      }

      // =====================================================
      // GET OWNER GPS
      // =====================================================

      final Position? ownerPosition =
          await _getOwnerLocation();

      if (!mounted) {
        return;
      }

      if (ownerPosition == null) {
        setState(() {
          _checkingAddress = false;
        });

        return;
      }

      setState(() {
        _ownerPosition = ownerPosition;
      });

      // =====================================================
      // START SEARCH
      // =====================================================

      await _startSearch(
        ownerId: ownerId,
        ownerAuthUid: user.uid,
        ownerName: ownerName,
        address: address,
        ownerLatitude:
            ownerPosition.latitude,
        ownerLongitude:
            ownerPosition.longitude,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Insta Walk owner profile Firestore error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingAddress = false;
      });

      _showMessage(
        e.code == 'permission-denied'
            ? 'You do not have permission to check your owner profile.'
            : 'Unable to check owner profile. Please try again.',
      );
    } catch (e) {
      debugPrint(
        'Insta Walk owner profile error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingAddress = false;
      });

      _showMessage(
        'Unable to check owner profile. Please try again.',
      );
    }
  }

  // =========================================================
  // START SEARCH
  // =========================================================

  Future<void> _startSearch({
    required String ownerId,
    required String ownerAuthUid,
    required String ownerName,
    required String address,
    required double ownerLatitude,
    required double ownerLongitude,
  }) async {
    _timer?.cancel();
    await _requestSubscription?.cancel();

    final DateTime now =
        DateTime.now();

    final DateTime expiresAt =
        now.add(
      const Duration(
        seconds: _searchDurationSeconds,
      ),
    );

    try {
      // =====================================================
      // CREATE REQUEST
      // =====================================================

      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(
                _walkRequestsCollection,
              )
              .doc();

      await requestRef.set({
        // ===================================================
        // OWNER
        // ===================================================

        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,

        // ===================================================
        // SENDER
        // ===================================================

        'senderUid': ownerAuthUid,
        'senderRole': 'owner',

        // ===================================================
        // OWNER NAME
        // ===================================================

        'ownerName': ownerName,

        // ===================================================
        // DESTINATION / ADDRESS
        // ===================================================

        'address': address,

        // ===================================================
        // OWNER LOCATION
        //
        // Walker matching ke liye.
        // Ye owner ka LIVE tracking nahi hai.
        // Ye request ke waqt saved location hai.
        // ===================================================

        'ownerLocation': GeoPoint(
          ownerLatitude,
          ownerLongitude,
        ),

        'ownerLatitude': ownerLatitude,
        'ownerLongitude': ownerLongitude,

        // ===================================================
        // SEARCH RADIUS
        // ===================================================

        'searchRadiusKm':
            _searchDistanceKm,

        'distanceKm':
            _searchDistanceKm,

        'locationType':
            'owner_pickup_location',

        // ===================================================
        // REQUEST STATUS
        // ===================================================

        'status': 'searching',

        // ===================================================
        // TIME
        // ===================================================

        'createdAt':
            FieldValue.serverTimestamp(),

        'expiresAt':
            Timestamp.fromDate(
          expiresAt,
        ),

        // ===================================================
        // WALKER
        //
        // Owner ko accept hone se pehle
        // koi walker information nahi milegi.
        // ===================================================

        'acceptedBy': null,
        'walkerUid': null,
        'walkerId': null,

        // ===================================================
        // WALKER LOCATION
        //
        // Accept hone ke baad fill hoga.
        // ===================================================

        'walkerLocation': null,
        'walkerLatitude': null,
        'walkerLongitude': null,
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _secondsLeft =
            _searchDurationSeconds;
        _requestId =
            requestRef.id;
      });

      // =====================================================
      // START RADAR
      // =====================================================

      _radarController.repeat();

      // =====================================================
      // LISTEN FOR ACCEPT
      // =====================================================

      _listenForRequest(
        requestRef,
      );

      // =====================================================
      // START TIMER
      // =====================================================

      _startTimer();
    } on FirebaseException catch (e) {
      debugPrint(
        'Create walk request Firestore error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingAddress = false;
        _searching = false;
      });

      _radarController.stop();

      _showMessage(
        e.code == 'permission-denied'
            ? 'Walk request was blocked by Firestore rules.'
            : 'Unable to create walk request. Please try again.',
      );
    } catch (e) {
      debugPrint(
        'Create walk request error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingAddress = false;
        _searching = false;
      });

      _radarController.stop();

      _showMessage(
        'Unable to create walk request. Please try again.',
      );
    }
  }

  // =========================================================
  // LISTEN FOR WALKER
  // =========================================================

  void _listenForRequest(
    DocumentReference<
        Map<String, dynamic>> requestRef,
  ) {
    _requestSubscription?.cancel();

    _requestSubscription =
        requestRef.snapshots().listen(
      (
        DocumentSnapshot<
            Map<String, dynamic>> snapshot,
      ) {
        if (!mounted ||
            !snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        // ===================================================
        // ACCEPTED
        // ===================================================

        if (status == 'accepted') {
          _handleWalkerAccepted(
            data,
          );

          return;
        }

        // ===================================================
        // CANCELLED
        // ===================================================

        if (status == 'cancelled' ||
            status == 'owner_cancelled' ||
            status == 'walker_cancelled') {
          _handleRequestCancelled();

          return;
        }

        // ===================================================
        // EXPIRED
        // ===================================================

        if (status == 'expired') {
          _finishSearch();

          return;
        }
      },
      onError: (Object error) {
        debugPrint(
          'Walk request listener error: $error',
        );
      },
    );
  }

  // =========================================================
  // WALKER ACCEPTED
  // =========================================================

  void _handleWalkerAccepted(
    Map<String, dynamic> data,
  ) {
    _timer?.cancel();
    _requestSubscription?.cancel();

    // =======================================================
    // RADAR OFF
    // =======================================================

    _radarController.stop();
    _radarController.reset();

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _searchFinished = false;
      _secondsLeft =
          _searchDurationSeconds;
    });

    // =======================================================
    // IMPORTANT
    //
    // Owner ko Walker ki information
    // sirf ACCEPTED ke baad milegi.
    // =======================================================

    widget.onWalkerFound?.call();

    _showMessage(
      'Walker accepted your walk request.',
    );
  }

  // =========================================================
  // FINISH SEARCH
  // =========================================================

  void _finishSearch() {
    _timer?.cancel();
    _requestSubscription?.cancel();

    _radarController.stop();
    _radarController.reset();

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _searchFinished = true;
      _secondsLeft = 0;
    });
  }

  // =========================================================
  // REQUEST CANCELLED
  // =========================================================

  void _handleRequestCancelled() {
    _timer?.cancel();
    _requestSubscription?.cancel();

    _radarController.stop();
    _radarController.reset();

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _searchFinished = true;
      _secondsLeft = 0;
    });

    _showMessage(
      'Walk request was cancelled.',
    );
  }

  // =========================================================
  // TIMER
  // =========================================================

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (!_searching) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 1) {
          timer.cancel();

          await _expireRequest();

          if (!mounted) {
            return;
          }

          _radarController.stop();
          _radarController.reset();

          setState(() {
            _searching = false;
            _searchFinished = true;
            _secondsLeft = 0;
          });

          return;
        }

        setState(() {
          _secondsLeft--;
        });
      },
    );
  }

  // =========================================================
  // EXPIRE REQUEST
  // =========================================================

  Future<void> _expireRequest() async {
    final String? requestId =
        _requestId;

    if (requestId == null ||
        requestId.trim().isEmpty) {
      return;
    }

    try {
      final DocumentReference<
          Map<String, dynamic>> requestRef =
          _firestore
              .collection(
                _walkRequestsCollection,
              )
              .doc(requestId);

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await requestRef.get();

      if (!snapshot.exists) {
        return;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      final String status =
          data?['status']
                  ?.toString()
                  .trim() ??
              '';

      // =====================================================
      // ACCEPTED REQUEST KO EXPIRE NAHI KARNA
      // =====================================================

      if (status == 'searching') {
        await requestRef.update({
          'status': 'expired',
          'expiredAt':
              FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'Expire walk request Firestore error: '
        '${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'Expire walk request error: $e',
      );
    }
  }

  // =========================================================
  // RETRY
  // =========================================================

  Future<void> _retrySearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _searchFinished = false;
    });

    await _findWalker();
  }

  // =========================================================
  // TIMER TEXT
  // =========================================================

  String _timerText() {
    final String minutes =
        (_secondsLeft ~/ 60)
            .toString()
            .padLeft(2, '0');

    final String seconds =
        (_secondsLeft % 60)
            .toString()
            .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        8,
      ),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(20),
        decoration:
            BoxDecoration(
          gradient:
              const LinearGradient(
            colors: [
              Color(0xFFE45D32),
              Color(0xFFC84A24),
            ],
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: .08,
              ),
              blurRadius: 18,
              offset:
                  const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // HEADER
            // =================================================

            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white
                            .withValues(
                      alpha: .18,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(16),
                  ),
                  child: const Icon(
                    Icons
                        .flash_on_rounded,
                    color:
                        Colors.white,
                    size: 29,
                  ),
                ),

                const SizedBox(
                  width: 13,
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Insta Walk',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize:
                              21,
                          fontWeight:
                              FontWeight
                                  .w800,
                        ),
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Text(
                        'Find a walker right now',
                        style:
                            TextStyle(
                          color:
                              Colors.white70,
                          fontSize:
                              13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'We search for an online and available walker within 3 km.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            if (!_searching &&
                !_searchFinished)
              _findButton(),

            if (_searching)
              _searchingContainer(),

            if (_searchFinished)
              _retryContainer(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FIND BUTTON
  // =========================================================

  Widget _findButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child:
          ElevatedButton.icon(
        onPressed:
            _checkingAddress
                ? null
                : _findWalker,

        icon: _checkingAddress
            ? const SizedBox(
                height: 18,
                width: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Color(0xFFE45D32),
                  ),
                ),
              )
            : const Icon(
                Icons.search_rounded,
              ),

        label: Text(
          _checkingAddress
              ? 'Checking Address...'
              : 'Find a Walker',
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),

        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              Colors.white,
          foregroundColor:
              const Color(
            0xFFE45D32,
          ),
          disabledBackgroundColor:
              Colors.white,
          disabledForegroundColor:
              const Color(
            0xFFE45D32,
          ),
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
    );
  }

  // =========================================================
  // SEARCHING UI
  // =========================================================

  Widget _searchingContainer() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(
              height: 20,
              width: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<
                        Color>(
                  Colors.white,
                ),
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            const Expanded(
              child: Text(
                'Searching for a walker...',
                style: TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            Text(
              _timerText(),
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        // =====================================================
        // MAP + RADAR
        // =====================================================

        if (_ownerPosition != null)
          _searchMapRadar(),

        const SizedBox(
          height: 12,
        ),

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(13),
          decoration:
              BoxDecoration(
            color:
                Colors.white.withValues(
              alpha: .13,
            ),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons
                    .location_on_outlined,
                color:
                    Colors.white,
                size: 18,
              ),
              SizedBox(
                width: 7,
              ),
              Expanded(
                child: Text(
                  'Searching nearby online walkers. The search will continue until a walker accepts or 2 minutes are completed.',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        11,
                    height:
                        1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        Text(
          'Maximum search distance: 3 km',
          style: TextStyle(
            color:
                Colors.white.withValues(
              alpha: .75,
            ),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MAP + RADAR
  // =========================================================

  Widget _searchMapRadar() {
    final Position? position =
        _ownerPosition;

    if (position == null) {
      return const SizedBox.shrink();
    }

    final LatLng ownerPoint =
        LatLng(
      position.latitude,
      position.longitude,
    );

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16),
      child: SizedBox(
        height: 145,
        width: double.infinity,
        child: Stack(
          children: [
            // =================================================
            // MAP
            // =================================================

            FlutterMap(
              options:
                  MapOptions(
                initialCenter:
                    ownerPoint,
                initialZoom: 14.5,
                interactionOptions:
                    const InteractionOptions(
                  flags:
                      InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.doojowalker.app',
                ),

                // ===========================================
                // 3 KM SEARCH AREA
                // ===========================================

                CircleLayer(
                  circles: [
                    CircleMarker(
                      point:
                          ownerPoint,
                      radius:
                          3000,
                      useRadiusInMeter:
                          true,
                      color:
                          const Color(
                        0xFFE45D32,
                      ).withValues(
                        alpha: .07,
                      ),
                      borderColor:
                          const Color(
                        0xFFE45D32,
                      ).withValues(
                        alpha: .45,
                      ),
                      borderStrokeWidth:
                          1.5,
                    ),
                  ],
                ),

                // ===========================================
                // OWNER MARKER
                // ===========================================

                MarkerLayer(
                  markers: [
                    Marker(
                      point:
                          ownerPoint,
                      width: 34,
                      height: 34,
                      child:
                          Container(
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFE45D32,
                          ),
                          shape:
                              BoxShape.circle,
                          border:
                              Border.all(
                            color:
                                Colors.white,
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color:
                                  Colors.black26,
                              blurRadius:
                                  7,
                            ),
                          ],
                        ),
                        child:
                            const Icon(
                          Icons
                              .home_rounded,
                          color:
                              Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // =================================================
            // RADAR ANIMATION
            // =================================================

            Positioned.fill(
              child:
                  IgnorePointer(
                child:
                    AnimatedBuilder(
                  animation:
                      _radarController,
                  builder:
                      (
                    BuildContext context,
                    Widget? child,
                  ) {
                    return CustomPaint(
                      painter:
                          _RadarPainter(
                        progress:
                            _radarController
                                .value,
                      ),
                    );
                  },
                ),
              ),
            ),

            // =================================================
            // SEARCHING LABEL
            // =================================================

            Positioned(
              left: 10,
              top: 9,
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.black
                          .withValues(
                    alpha: .55,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child:
                    const Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons
                          .radar_rounded,
                      color:
                          Colors.white,
                      size: 15,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Searching nearby',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // 3 KM LABEL
            // =================================================

            Positioned(
              right: 10,
              bottom: 9,
              child: Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white
                          .withValues(
                    alpha: .92,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child:
                    const Text(
                  'Within 3 km',
                  style:
                      TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF263746),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SEARCH FINISHED
  // =========================================================

  Widget _retryContainer() {
    return Column(
      children: [
        const Row(
          children: [
            Icon(
              Icons
                  .person_search_rounded,
              color:
                  Colors.white,
              size: 21,
            ),
            SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                'No walker accepted the request',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        SizedBox(
          width: double.infinity,
          height: 50,
          child:
              ElevatedButton.icon(
            onPressed:
                _retrySearch,
            icon: const Icon(
              Icons
                  .refresh_rounded,
            ),
            label:
                const Text(
              'Re-search',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  Colors.black,
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
      ],
    );
  }
}

// ================================================================
// RADAR PAINTER
// ================================================================

class _RadarPainter
    extends CustomPainter {
  final double progress;

  _RadarPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center =
        Offset(
      size.width / 2,
      size.height / 2,
    );

    final double maxRadius =
        math.min(
              size.width,
              size.height,
            ) *
            .43;

    // ==========================================================
    // RADAR RINGS
    // ==========================================================

    final Paint ringPaint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1
          ..color =
              const Color(
            0xFFE45D32,
          ).withValues(
            alpha: .28,
          );

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        maxRadius * i / 3,
        ringPaint,
      );
    }

    // ==========================================================
    // PULSE
    // ==========================================================

    final double pulseRadius =
        maxRadius *
            (0.35 +
                progress * .65);

    final Paint pulsePaint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 2
          ..color =
              const Color(
            0xFFE45D32,
          ).withValues(
            alpha:
                (1 - progress) *
                    .45,
          );

    canvas.drawCircle(
      center,
      pulseRadius,
      pulsePaint,
    );

    // ==========================================================
    // SWEEP
    // ==========================================================

    final double sweepAngle =
        progress *
            math.pi *
            2;

    final Paint sweepPaint =
        Paint()
          ..shader =
              SweepGradient(
            startAngle:
                sweepAngle - .9,
            endAngle:
                sweepAngle,
            colors: [
              const Color(
                0xFFE45D32,
              ).withValues(
                alpha: 0,
              ),
              const Color(
                0xFFE45D32,
              ).withValues(
                alpha: .38,
              ),
            ],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius:
                  maxRadius,
            ),
          );

    canvas.drawCircle(
      center,
      maxRadius,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _RadarPainter oldDelegate,
  ) {
    return oldDelegate.progress !=
        progress;
  }
}
