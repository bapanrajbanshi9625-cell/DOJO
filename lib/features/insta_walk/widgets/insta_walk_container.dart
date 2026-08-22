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

  /// true = searching / accepted / active
  /// false = finished / cancelled / expired / inactive
  final ValueChanged<bool>? onActiveChanged;

  /// false = compact Insta Walk patti
  /// true = complete Insta Walk interface
  final bool fullScreen;

  /// Called when compact Insta Walk patti is tapped.
  final VoidCallback? onTap;

  const InstaWalkContainer({
    super.key,
    this.onWalkerFound,
    this.onActiveChanged,
    this.fullScreen = false,
    this.onTap,
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
  // TIMER
  // ==========================================================

  Timer? _timer;

  // ==========================================================
  // RADAR
  // ==========================================================

  late final AnimationController _radarController;

  // ==========================================================
  // SEARCH STATE
  // ==========================================================

  bool _searching = false;
  bool _searchFinished = false;
  bool _checkingAddress = false;
  bool _recovering = true;

  // ==========================================================
  // ACTIVE STATE
  // ==========================================================

  bool _activeReported = false;

  // ==========================================================
  // TIMER STATE
  // ==========================================================

  int _secondsLeft = 0;

  // ==========================================================
  // REQUEST
  // ==========================================================

  String? _requestId;

  // ==========================================================
  // LOCATION
  // ==========================================================

  Position? _ownerPosition;

  // ==========================================================
  // PET
  // ==========================================================

  String _petName = 'Your Pet';

  // ==========================================================
  // DURATION
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
      duration: const Duration(seconds: 2),
    );

    _recoverSearch();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _stopTimer();
    _stopRadar();

    _service.dispose();
    _radarController.dispose();

    super.dispose();
  }

  // ==========================================================
  // ACTIVE STATE
  // ==========================================================

  void _setActive(bool active) {
    if (_activeReported == active) {
      return;
    }

    _activeReported = active;

    widget.onActiveChanged?.call(active);
  }

  // ==========================================================
  // TIMER STOP
  // ==========================================================

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ==========================================================
  // RADAR STOP
  // ==========================================================

  void _stopRadar() {
    if (!_radarController.isAnimating &&
        _radarController.value == 0) {
      return;
    }

    _radarController.stop();
    _radarController.reset();
  }

  // ==========================================================
  // RESET
  // ==========================================================

  void _resetSearchState({
    bool finished = false,
  }) {
    _stopTimer();
    _stopRadar();

    _requestId = null;
    _secondsLeft = 0;
    _ownerPosition = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _searchFinished = finished;
      _checkingAddress = false;
    });
  }

  // ==========================================================
  // RECOVER SEARCH
  // ==========================================================

  Future<void> _recoverSearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recovering = false;
        _searching = false;
        _searchFinished = false;
        _checkingAddress = false;
      });

      _setActive(false);
      return;
    }

    try {
      final QueryDocumentSnapshot<Map<String, dynamic>>?
          ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) {
        return;
      }

      if (ownerDoc == null) {
        setState(() {
          _recovering = false;
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
        });

        _setActive(false);
        return;
      }

      final Map<String, dynamic> ownerData =
          ownerDoc.data();

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
          _searching = false;
          _searchFinished = false;
        });

        _setActive(false);
        return;
      }

      final InstaWalkRequestState? active =
          await _service.findActiveRequest(
        ownerId: ownerId,
      );

      if (!mounted) {
        return;
      }

      if (active == null) {
        setState(() {
          _recovering = false;
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
          _secondsLeft = 0;
        });

        _setActive(false);
        return;
      }

      if (active.isSearching) {
        await _recoverSearchingRequest(
          active,
        );
        return;
      }

      if (active.isAccepted) {
        _recoverAcceptedRequest(active);
        return;
      }

      _resetSearchState();

      if (!mounted) {
        return;
      }

      setState(() {
        _recovering = false;
      });

      _setActive(false);
    } catch (e) {
      debugPrint(
        'Insta Walk recovery error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _recovering = false;
        _searching = false;
        _searchFinished = false;
        _checkingAddress = false;
      });

      _setActive(false);
    }
  }

  // ==========================================================
  // RECOVER SEARCHING
  // ==========================================================

  Future<void> _recoverSearchingRequest(
    InstaWalkRequestState active,
  ) async {
    final String? requestId =
        active.requestId;

    final DateTime? expiresAt =
        active.expiresAt;

    if (requestId == null ||
        requestId.trim().isEmpty ||
        expiresAt == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _recovering = false;
        _searching = false;
        _searchFinished = false;
      });

      _setActive(false);
      return;
    }

    Duration remaining =
        expiresAt.difference(
      DateTime.now(),
    );

    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

    if (remaining.inSeconds <= 0) {
      await _service.expireRequest(
        requestId: requestId,
      );

      if (!mounted) {
        return;
      }

      _requestId = null;
      _ownerPosition = null;

      setState(() {
        _recovering = false;
        _searching = false;
        _searchFinished = false;
        _checkingAddress = false;
        _secondsLeft = 0;
      });

      _setActive(false);
      return;
    }

    final Position? recoveredPosition =
        _readOwnerPosition(
      active.data,
    );

    _requestId = requestId;
    _currentDuration = remaining;
    _ownerPosition = recoveredPosition;

    setState(() {
      _recovering = false;
      _searching = true;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = remaining.inSeconds;
    });

    _setActive(true);

    _startRadar();

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

    if (!mounted) {
      return;
    }

    if (_searching) {
      _startTimer();
    }
  }

  // ==========================================================
  // RECOVER ACCEPTED
  // ==========================================================

  void _recoverAcceptedRequest(
    InstaWalkRequestState active,
  ) {
    final Map<String, dynamic> data =
        active.data ?? {};

    final InstaWalkAcceptedData accepted =
        InstaWalkAcceptedData.fromMap(
      data,
    );

    _requestId =
        accepted.requestId.trim().isEmpty
            ? active.requestId
            : accepted.requestId;

    _stopTimer();
    _stopRadar();

    if (!mounted) {
      return;
    }

    setState(() {
      _recovering = false;
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = 0;
    });

    _setActive(true);

    widget.onWalkerFound?.call();
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
      final QueryDocumentSnapshot<Map<String, dynamic>>?
          ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) {
        return;
      }

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

      final String address =
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

        if (!mounted) {
          return;
        }

        setState(() {
          _checkingAddress = false;
        });

        return;
      }

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

      final Position? position =
          await _getLocation();

      if (!mounted) {
        return;
      }

      if (position == null) {
        setState(() {
          _checkingAddress = false;
        });
        return;
      }

      _ownerPosition = position;

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

      if (!mounted) {
        return;
      }

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

      return await Geolocator.getCurrentPosition();
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
    _stopTimer();

    try {
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

      if (!mounted) {
        return;
      }

      if (!result.success ||
          result.requestId == null ||
          result.expiresAt == null) {
        setState(() {
          _checkingAddress = false;
          _searching = false;
          _searchFinished = false;
          _secondsLeft = 0;
        });

        _requestId = null;

        _stopRadar();
        _setActive(false);

        _message(
          result.message ??
              'Unable to start search.',
        );

        return;
      }

      _requestId =
          result.requestId;

      _currentDuration =
          result.duration ??
              InstaWalkSearchService
                  .normalSearchDuration;

      Duration remaining =
          result.expiresAt!.difference(
        DateTime.now(),
      );

      if (remaining.isNegative) {
        remaining = Duration.zero;
      }

      if (remaining.inSeconds <= 0) {
        await _service.expireRequest(
          requestId: result.requestId!,
        );

        if (!mounted) {
          return;
        }

        _resetSearchState();

        _setActive(false);

        _message(
          'Search expired. Please try again.',
        );

        return;
      }

      setState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _secondsLeft =
            remaining.inSeconds;
      });

      _setActive(true);

      _startRadar();

      await _service.listenForRequest(
        requestId:
            result.requestId!,
        onAccepted:
            _walkerAccepted,
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

      if (!mounted) {
        return;
      }

      if (_searching) {
        _startTimer();
      }
    } catch (e) {
      debugPrint(
        'Insta Walk search error: $e',
      );

      if (!mounted) {
        return;
      }

      _stopTimer();
      _stopRadar();

      setState(() {
        _checkingAddress = false;
        _searching = false;
        _searchFinished = false;
        _secondsLeft = 0;
      });

      _requestId = null;

      _setActive(false);

      _message(
        'Unable to start Insta Walk.',
      );
    }
  }

  // ==========================================================
  // RADAR
  // ==========================================================

  void _startRadar() {
    if (!mounted) {
      return;
    }

    if (!_radarController.isAnimating) {
      _radarController.repeat();
    }
  }

  // ==========================================================
  // TIMER
  // ==========================================================

  void _startTimer() {
    _stopTimer();

    if (!mounted ||
        !_searching) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) async {
        if (!mounted ||
            !_searching) {
          timer.cancel();
          return;
        }

        final String? id =
            _requestId;

        if (id == null ||
            id.trim().isEmpty) {
          timer.cancel();
          _timer = null;

          _finishSearch();
          return;
        }

        if (_secondsLeft <= 1) {
          timer.cancel();
          _timer = null;

          final InstaWalkRequestState state =
              await _service.getRequestState(
            id,
          );

          if (!mounted) {
            return;
          }

          if (state.isAccepted) {
            _walkerAccepted(
              InstaWalkAcceptedData.fromMap(
                state.data ?? {},
              ),
            );
            return;
          }

          if (state.isSearching) {
            await _service.expireRequest(
              requestId: id,
            );
          }

          if (!mounted) {
            return;
          }

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
    _stopTimer();
    _stopRadar();

    if (!mounted) {
      return;
    }

    _requestId =
        data.requestId.trim().isEmpty
            ? _requestId
            : data.requestId;

    setState(() {
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = 0;
    });

    _setActive(true);

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
  // FINISH SEARCH
  // ==========================================================

  void _finishSearch({
    String? message,
  }) {
    _stopTimer();
    _stopRadar();

    _requestId = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _searchFinished = true;
      _checkingAddress = false;
      _secondsLeft = 0;
    });

    _setActive(false);

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
    final int safeSeconds =
        _secondsLeft < 0
            ? 0
            : _secondsLeft;

    final int minutes =
        safeSeconds ~/ 60;

    final int seconds =
        safeSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _message(String text) {
    if (!mounted) {
      return;
    }

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            maxLines: 3,
            overflow:
                TextOverflow.ellipsis,
          ),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(16),
          duration:
              const Duration(seconds: 3),
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
  Widget build(BuildContext context) {
    if (widget.fullScreen) {
      return _buildFullScreen();
    }

    return _buildCompactPatti();
  }

  // ==========================================================
  // COMPACT PATTI
  // ==========================================================

  Widget _buildCompactPatti() {
    final Widget patti =
        Container(
      width: double.infinity,
      height: 68,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF243746),
            Color(0xFF304E5A),
            Color(0xFF376A70),
          ],
          begin:
              Alignment.centerLeft,
          end:
              Alignment.centerRight,
        ),
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              const Color(0xFF65D6C8)
                  .withValues(
            alpha: .20,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: .10,
            ),
            blurRadius: 16,
            offset:
                const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF65D6C8)
                      .withValues(
                alpha: .14,
              ),
              shape:
                  BoxShape.circle,
              border:
                  Border.all(
                color:
                    const Color(0xFF65D6C8)
                        .withValues(
                  alpha: .20,
                ),
              ),
            ),
            child:
                const Icon(
              Icons.flash_on_rounded,
              color:
                  Color(0xFF8FFFEF),
              size: 21,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Insta Walk',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _searching
                      ? 'Finding walker for $_petName'
                      : 'Walker is active',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFF65D6C8)
                      .withValues(
                alpha: .14,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child:
                Text(
              _searching
                  ? 'LIVE'
                  : 'ACTIVE',
              style:
                  const TextStyle(
                color:
                    Color(0xFF8FFFEF),
                fontSize: 8,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          const Icon(
            Icons.chevron_right_rounded,
            color:
                Colors.white70,
            size: 23,
          ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return patti;
    }

    return GestureDetector(
      onTap: widget.onTap,
      behavior:
          HitTestBehavior.opaque,
      child: patti,
    );
  }

  // ==========================================================
  // FULL SCREEN
  // ==========================================================

  Widget _buildFullScreen() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        20,
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
          border:
              Border.all(
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
        child:
            _buildFullScreenContent(),
      ),
    );
  }

  // ==========================================================
  // FULL SCREEN CONTENT
  // ==========================================================

  Widget _buildFullScreenContent() {
    if (_recovering) {
      return const SizedBox(
        height: 180,
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
          height: 16,
        ),

        Text(
          _searching
              ? 'Searching available walkers near your current location.'
              : 'Find an available walker nearby instantly.',
          style:
              const TextStyle(
            color:
                Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        if (!_searching &&
            !_searchFinished)
          SizedBox(
            width: double.infinity,
            child:
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
          ),

        if (_searching)
          _buildSearching(),

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
    if (_ownerPosition != null) {
      return InstaWalkSearching(
        timerText:
            _timerText(),
        map:
            InstaWalkMapRadar(
          ownerPoint:
              LatLng(
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

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            Colors.black.withValues(
          alpha: .12,
        ),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child:
          Column(
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

          const Text(
            'Searching nearby walkers',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  Colors.white,
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
    final bool isLive =
        _searching;

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
                BorderRadius.circular(17),
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
                CrossAxisAlignment.start,
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
                isLive
                    ? 'Finding a walker for $_petName'
                    : 'Walker is active',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
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
              const EdgeInsets.symmetric(
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
                    const BoxDecoration(
                  color:
                      Color(0xFF65D6C8),
                  shape:
                      BoxShape.circle,
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                isLive
                    ? 'LIVE'
                    : 'ACTIVE',
                style:
                    const TextStyle(
                  color:
                      Color(0xFF8FFFEF),
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
