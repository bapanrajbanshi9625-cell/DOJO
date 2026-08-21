import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../screens/address_screen.dart';
import '../services/insta_walk_search_service.dart';
import 'insta_walk_map_radar.dart';
import 'insta_walk_retry.dart';
import 'insta_walk_search_button.dart';
import 'insta_walk_searching.dart';

class InstaWalkContainer extends StatefulWidget {
  final VoidCallback? onWalkerFound;

  /// false = Home compact card
  /// true  = Full Insta Walk screen
  final bool fullScreen;

  const InstaWalkContainer({
    super.key,
    this.onWalkerFound,
    this.fullScreen = false,
  });

  @override
  State<InstaWalkContainer> createState() =>
      _InstaWalkContainerState();
}

class _InstaWalkContainerState
    extends State<InstaWalkContainer>
    with SingleTickerProviderStateMixin {
  // ==========================================================
  // SERVICE
  // ==========================================================

  late final InstaWalkSearchService _service;

  // ==========================================================
  // TIMERS
  // ==========================================================

  Timer? _timer;

  // ==========================================================
  // RADAR
  // ==========================================================

  late final AnimationController _radarController;

  // ==========================================================
  // UI STATE
  // ==========================================================

  bool _searching = false;
  bool _searchFinished = false;
  bool _checkingAddress = false;
  bool _recovering = true;

  // ==========================================================
  // TIMER STATE
  // ==========================================================

  int _secondsLeft = 0;

  // ==========================================================
  // REQUEST
  // ==========================================================

  String? _requestId;

  // ==========================================================
  // OWNER LOCATION
  // ==========================================================

  Position? _ownerPosition;

  // ==========================================================
  // OWNER / PET
  // ==========================================================

  String _petName = 'Your Pet';

  // ==========================================================
  // SEARCH DURATION
  // ==========================================================

  Duration _currentDuration =
      InstaWalkSearchService.firstSearchDuration;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _service = InstaWalkSearchService();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 2,
      ),
    );

    _recoverSearch();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _timer?.cancel();

    _service.dispose();

    _radarController.dispose();

    super.dispose();
  }

  // ==========================================================
  // RECOVER ACTIVE INSTA WALK
  // ==========================================================

  Future<void> _recoverSearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _recovering = false;
        });
      }

      return;
    }

    try {
      // ======================================================
      // FIND OWNER PROFILE
      // ======================================================

      final QueryDocumentSnapshot<
          Map<String, dynamic>>? ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) return;

      if (ownerDoc == null) {
        setState(() {
          _recovering = false;
        });

        return;
      }

      final Map<String, dynamic> ownerData =
          ownerDoc.data();

      // ======================================================
      // PET NAME
      // ======================================================

      _petName = _readFirstString(
        ownerData,
        const [
          'petName',
          'Pet Name',
          'dogName',
          'Dog Name',
        ],
      );

      if (_petName.isEmpty) {
        _petName = 'Your Pet';
      }

      // ======================================================
      // OWNER ID
      // ======================================================

      final String ownerId =
          _readFirstString(
        ownerData,
        const [
          'ownerId',
          'Owner ID',
        ],
      );

      if (ownerId.isEmpty) {
        setState(() {
          _recovering = false;
        });

        return;
      }

      // ======================================================
      // FIND ACTIVE FIRESTORE REQUEST
      // ======================================================

      final InstaWalkRequestState? active =
          await _service.findActiveRequest(
        ownerId: ownerId,
      );

      if (!mounted) return;

      // ======================================================
      // NO ACTIVE REQUEST
      // ======================================================

      if (active == null) {
        setState(() {
          _recovering = false;
        });

        return;
      }

      // ======================================================
      // ACTIVE SEARCH
      // ======================================================

      if (active.isSearching) {
        final String? requestId =
            active.requestId;

        final DateTime? expiresAt =
            active.expiresAt;

        if (requestId == null ||
            requestId.trim().isEmpty ||
            expiresAt == null) {
          setState(() {
            _recovering = false;
          });

          return;
        }

        // ====================================================
        // CALCULATE REAL REMAINING TIME
        // ====================================================

        Duration remaining =
            expiresAt.difference(
          DateTime.now(),
        );

        if (remaining.isNegative) {
          remaining = Duration.zero;
        }

        // ====================================================
        // RECOVER LOCATION
        // ====================================================

        final Position? recoveredPosition =
            _readOwnerPosition(
          active.data,
        );

        // ====================================================
        // STORE RECOVERED STATE
        // ====================================================

        _requestId = requestId;

        _currentDuration = remaining;

        _ownerPosition =
            recoveredPosition;

        setState(() {
          _recovering = false;
          _searching = true;
          _searchFinished = false;
          _checkingAddress = false;
          _secondsLeft =
              remaining.inSeconds;
        });

        // ====================================================
        // RADAR
        // ====================================================

        _radarController.repeat();

        // ====================================================
        // FIRESTORE LISTENER
        // ====================================================

        await _service.listenForRequest(
          requestId: requestId,
          onAccepted: _walkerAccepted,
          onExpired: () {
            _finishSearch();
          },
          onCancelled: () {
            _finishSearch(
              message:
                  'Walk request was cancelled.',
            );
          },
          onError: (Object error) {
            debugPrint(
              'Insta Walk listener error: $error',
            );
          },
        );

        if (!mounted) return;

        // ====================================================
        // START RECOVERED TIMER
        // ====================================================

        _startTimer();

        return;
      }

      // ======================================================
      // ACCEPTED
      // ======================================================

      if (active.isAccepted) {
        final Map<String, dynamic> data =
            active.data ?? {};

        final InstaWalkAcceptedData accepted =
            InstaWalkAcceptedData.fromMap(
          data,
        );

        _requestId =
            accepted.requestId.isEmpty
                ? null
                : accepted.requestId;

        setState(() {
          _recovering = false;
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
          _secondsLeft = 0;
        });

        widget.onWalkerFound?.call();

        return;
      }

      // ======================================================
      // OTHER STATE
      // ======================================================

      setState(() {
        _recovering = false;
      });
    } catch (e) {
      debugPrint(
        'Insta Walk recovery error: $e',
      );

      if (!mounted) return;

      setState(() {
        _recovering = false;
      });
    }
  }

  // ==========================================================
  // FIND WALKER
  // ==========================================================

  Future<void> _findWalker() async {
    if (_searching ||
        _checkingAddress ||
        _recovering) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message(
        'Please login first.',
      );

      return;
    }

    setState(() {
      _checkingAddress = true;
      _searchFinished = false;
    });

    try {
      // ======================================================
      // OWNER PROFILE
      // ======================================================

      final QueryDocumentSnapshot<
          Map<String, dynamic>>? ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) return;

      if (ownerDoc == null) {
        setState(() {
          _checkingAddress = false;
        });

        _message(
          'Owner profile not found. Please complete your profile.',
        );

        return;
      }

      final Map<String, dynamic> data =
          ownerDoc.data();

      // ======================================================
      // OWNER ID
      // ======================================================

      final String ownerId =
          _readFirstString(
        data,
        const [
          'ownerId',
          'Owner ID',
        ],
      );

      if (ownerId.isEmpty) {
        setState(() {
          _checkingAddress = false;
        });

        _message(
          'Owner ID not found.',
        );

        return;
      }

      // ======================================================
      // PET NAME
      // ======================================================

      _petName = _readFirstString(
        data,
        const [
          'petName',
          'Pet Name',
          'dogName',
          'Dog Name',
        ],
      );

      if (_petName.isEmpty) {
        _petName = 'Your Pet';
      }

      // ======================================================
      // ADDRESS
      // ======================================================

      String address =
          _readFirstString(
        data,
        const [
          'address',
          'Adress',
          'Address',
        ],
      );

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

        if (!mounted) return;

        setState(() {
          _checkingAddress = false;
        });

        // ====================================================
        // TRY AGAIN AFTER ADDRESS SETUP
        // ====================================================

        return;
      }

      // ======================================================
      // OWNER NAME
      // ======================================================

      String ownerName =
          _readFirstString(
        data,
        const [
          'fullName',
          'Full Name',
          'ownerName',
          'name',
        ],
      );

      if (ownerName.isEmpty) {
        ownerName = 'Dog Owner';
      }

      // ======================================================
      // LOCATION
      // ======================================================

      final Position? position =
          await _getLocation();

      if (!mounted) return;

      if (position == null) {
        setState(() {
          _checkingAddress = false;
        });

        return;
      }

      _ownerPosition = position;

      // ======================================================
      // START SEARCH
      // ======================================================

      await _startSearch(
        ownerId: ownerId,
        ownerName: ownerName,
        address: address,
        position: position,
      );
    } catch (e) {
      debugPrint(
        'Insta Walk start error: $e',
      );

      if (!mounted) return;

      setState(() {
        _checkingAddress = false;
      });

      _message(
        'Unable to start Insta Walk.',
      );
    }
  }

  // ==========================================================
  // LOCATION
  // ==========================================================

  Future<Position?> _getLocation() async {
    try {
      final bool enabled =
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        _message(
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
              LocationPermission.deniedForever) {
        _message(
          'Location permission is required.',
        );

        return null;
      }

      return Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint(
        'Location error: $e',
      );

      _message(
        'Unable to get your current location.',
      );

      return null;
    }
  }

  // ==========================================================
  // START SEARCH
  // ==========================================================

  Future<void> _startSearch({
    required String ownerId,
    required String ownerName,
    required String address,
    required Position position,
  }) async {
    _timer?.cancel();

    final InstaWalkSearchResult result =
        await _service.startSearch(
      ownerId: ownerId,
      ownerName: ownerName,
      address: address,
      ownerLocation: GeoPoint(
        position.latitude,
        position.longitude,
      ),
    );

    if (!mounted) return;

    if (!result.success ||
        result.requestId == null ||
        result.expiresAt == null) {
      setState(() {
        _checkingAddress = false;
        _searching = false;
      });

      _message(
        result.message ??
            'Unable to start search.',
      );

      return;
    }

    // ========================================================
    // SAVE REQUEST
    // ========================================================

    _requestId =
        result.requestId;

    _currentDuration =
        result.duration ??
            InstaWalkSearchService
                .normalSearchDuration;

    Duration remaining =
        result.expiresAt!
            .difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

    // ========================================================
    // UI
    // ========================================================

    setState(() {
      _checkingAddress = false;
      _searching = true;
      _searchFinished = false;
      _secondsLeft =
          remaining.inSeconds;
    });

    // ========================================================
    // RADAR
    // ========================================================

    _radarController.repeat();

    // ========================================================
    // FIRESTORE LISTENER
    // ========================================================

    await _service.listenForRequest(
      requestId: result.requestId!,
      onAccepted: _walkerAccepted,
      onExpired: () {
        _finishSearch();
      },
      onCancelled: () {
        _finishSearch(
          message:
              'Walk request was cancelled.',
        );
      },
      onError: (Object error) {
        debugPrint(
          'Insta Walk listener error: $error',
        );
      },
    );

    if (!mounted) return;

    // ========================================================
    // TIMER
    // ========================================================

    _startTimer();
  }

  // ==========================================================
  // TIMER
  // ==========================================================

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (!mounted ||
            !_searching) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 1) {
          timer.cancel();

          final String? id =
              _requestId;

          if (id != null &&
              id.trim().isNotEmpty) {
            await _service.expireRequest(
              requestId: id,
            );
          }

          if (!mounted) return;

          _finishSearch();

          return;
        }

        setState(() {
          _secondsLeft--;
        });
      },
    );
  }

  // ==========================================================
  // WALKER ACCEPTED
  // ==========================================================

  void _walkerAccepted(
    InstaWalkAcceptedData data,
  ) {
    _timer?.cancel();

    _radarController.stop();
    _radarController.reset();

    if (!mounted) return;

    setState(() {
      _searching = false;
      _searchFinished = false;
      _secondsLeft = 0;
    });

    widget.onWalkerFound?.call();

    final String name =
        data.walkerName.trim();

    _message(
      name.isEmpty
          ? 'Walker accepted your request.'
          : '$name accepted your request.',
    );
  }

  // ==========================================================
  // FINISH
  // ==========================================================

  void _finishSearch({
    String? message,
  }) {
    _timer?.cancel();

    _radarController.stop();
    _radarController.reset();

    if (!mounted) return;

    setState(() {
      _searching = false;
      _searchFinished = true;
      _secondsLeft = 0;
    });

    _message(
      message ??
          'No walker accepted the request.',
    );
  }

  // ==========================================================
  // RETRY
  // ==========================================================

  Future<void> _retrySearch() async {
    if (_searching ||
        _checkingAddress ||
        _recovering) {
      return;
    }

    setState(() {
      _searchFinished = false;
    });

    await _findWalker();
  }

  // ==========================================================
  // TIMER TEXT
  // ==========================================================

  String _timerText() {
    final int minutes =
        _secondsLeft ~/ 60;

    final int seconds =
        _secondsLeft % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _message(
    String text,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
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

  // ==========================================================
  // STRING READER
  // ==========================================================

  String _readFirstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value =
          data[key];

      if (value == null) {
        continue;
      }

      final String result =
          value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }

  // ==========================================================
  // LOCATION RECOVERY
  // ==========================================================

  Position? _readOwnerPosition(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }

    final dynamic value =
        data['ownerLocation'];

    if (value is GeoPoint) {
      return Position(
        longitude: value.longitude,
        latitude: value.latitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: widget.fullScreen
          ? const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              20,
            )
          : const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              8,
            ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          20,
        ),
        decoration: BoxDecoration(
          gradient:
              const LinearGradient(
            colors: [
              Color(0xFF243746),
              Color(0xFF304E5A),
              Color(0xFF376A70),
            ],
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(25),
          border: Border.all(
            color:
                const Color(0xFF65D6C8)
                    .withValues(
              alpha: .18,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: .10,
              ),
              blurRadius: 20,
              offset:
                  const Offset(0, 8),
            ),
          ],
        ),
        child: _buildContent(),
      ),
    );
  }

  // ==========================================================
  // CONTENT
  // ==========================================================

  Widget _buildContent() {
    if (_recovering) {
      return const SizedBox(
        height: 150,
        child: Center(
          child:
              CircularProgressIndicator(
            strokeWidth: 2.5,
            color:
                Color(0xFF65D6C8),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _header(),

        const SizedBox(
          height: 15,
        ),

        Text(
          _searching
              ? 'Searching available walkers near your current location.'
              : 'Find an available walker nearby instantly.',
          style:
              const TextStyle(
            color:
                Colors.white70,
            fontSize: 12.5,
            height: 1.45,
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        // ====================================================
        // SEARCH BUTTON
        // ====================================================

        if (!_searching &&
            !_searchFinished)
          InstaWalkSearchButton(
            loading:
                _checkingAddress,
            text:
                _checkingAddress
                    ? 'Checking location...'
                    : 'Find a Walker Now',
            onPressed:
                _checkingAddress
                    ? null
                    : _findWalker,
          ),

        // ====================================================
        // SEARCHING
        // ====================================================

        if (_searching)
          _buildSearching(),

        // ====================================================
        // RETRY
        // ====================================================

        if (_searchFinished)
          InstaWalkRetry(
            onRetry:
                _retrySearch,
          ),
      ],
    );
  }

  // ==========================================================
  // SEARCHING UI
  // ==========================================================

  Widget _buildSearching() {
    // If location snapshot is available,
    // show the existing map/radar widget.
    if (_ownerPosition != null) {
      return InstaWalkSearching(
        timerText:
            _timerText(),
        map:
            InstaWalkMapRadar(
          ownerPoint: LatLng(
            _ownerPosition!
                .latitude,
            _ownerPosition!
                .longitude,
          ),
          searchRadiusKm:
              InstaWalkSearchService
                  .searchRadiusKm,
          radarAnimation:
              _radarController,
        ),
      );
    }

    // ========================================================
    // FALLBACK
    //
    // This protects the UI if an old Firestore request does
    // not contain ownerLocation.
    // ========================================================

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
            Colors.black.withValues(
          alpha: .12,
        ),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 52,
            height: 52,
            child:
                CircularProgressIndicator(
              strokeWidth: 3,
              color:
                  Color(0xFF65D6C8),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            'Searching nearby walkers',
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            _timerText(),
            style:
                const TextStyle(
              color:
                  Color(0xFF8FFFEF),
              fontSize: 22,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration:
              BoxDecoration(
            gradient:
                const LinearGradient(
              colors: [
                Color(0xFF65D6C8),
                Color(0xFF8FFFEF),
              ],
            ),
            borderRadius:
                BorderRadius.circular(
              17,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    const Color(
                  0xFF65D6C8,
                ).withValues(
                  alpha: .25,
                ),
                blurRadius: 12,
              ),
            ],
          ),
          child:
              const Icon(
            Icons.flash_on_rounded,
            color:
                Color(0xFF243746),
            size: 29,
          ),
        ),

        const SizedBox(
          width: 13,
        ),

        Expanded(
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Text(
                'Insta Walk',
                style:
                    TextStyle(
                  color:
                      Colors.white,
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                _searching
                    ? 'Finding a walker for $_petName'
                    : 'Find a walker right now',
                maxLines: 1,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    const TextStyle(
                  color:
                      Colors.white60,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFF65D6C8,
            ).withValues(
              alpha: .12,
            ),
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border:
                Border.all(
              color:
                  const Color(
                0xFF65D6C8,
              ).withValues(
                alpha: .25,
              ),
            ),
          ),
          child:
              Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(
                  color:
                      _searching
                          ? const Color(
                              0xFF65D6C8,
                            )
                          : Colors.white54,
                  shape:
                      BoxShape.circle,
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                _searching
                    ? 'LIVE'
                    : 'READY',
                style:
                    TextStyle(
                  color:
                      _searching
                          ? const Color(
                              0xFF8FFFEF,
                            )
                          : Colors.white70,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
