import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/insta_walk_search_service.dart';

import 'insta_walk_map_radar.dart';
import 'insta_walk_retry.dart';
import 'insta_walk_search_button.dart';
import 'insta_walk_stop_button.dart';
import 'insta_walk_searching.dart';
import '../../../screens/address_screen.dart';

part 'insta_walk_view.dart';

// ============================================================
// INSTA WALK CONTAINER
// ============================================================

class InstaWalkContainer extends StatefulWidget {
  /// Called when a walker is found / accepted.
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

// ============================================================
// STATE
// ============================================================

class _InstaWalkContainerState extends State<InstaWalkContainer>
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
  // STOP STATE
  // ==========================================================

  bool _stopping = false;

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
  // STOP TIMER
  // ==========================================================

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ==========================================================
  // STOP RADAR
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
  // RESET SEARCH STATE
  // ==========================================================

  void _resetSearchState({
    bool finished = false,
  }) {
    _stopTimer();
    _stopRadar();

    _requestId = null;
    _secondsLeft = 0;
    _ownerPosition = null;
    _stopping = false;

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _searchFinished = finished;
      _checkingAddress = false;
      _recovering = false;
    });

    _setActive(false);
  }

  // ============================================================
  // STOP SEARCH
  // ============================================================

  Future<void> _stopSearch() async {
    if (_stopping) {
      return;
    }

    final String? requestId = _requestId;

    // ----------------------------------------------------------
    // No request ID = nothing to cancel
    // ----------------------------------------------------------

    if (requestId == null ||
        requestId.trim().isEmpty) {
      _resetSearchState();
      return;
    }

    // ----------------------------------------------------------
    // Only stop an active search
    // ----------------------------------------------------------

    if (!_searching) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _stopping = true;
    });

    try {
      // --------------------------------------------------------
      // Cancel request in Firestore
      // --------------------------------------------------------

      final bool cancelled =
          await _service.cancelSearch(
        requestId: requestId,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // Successfully cancelled
      // --------------------------------------------------------

      if (cancelled) {
        _stopTimer();
        _stopRadar();

        _requestId = null;
        _ownerPosition = null;

        setState(() {
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
          _recovering = false;
          _secondsLeft = 0;
          _stopping = false;
        });

        _setActive(false);

        _message('Insta Walk search stopped.');

        return;
      }

      // --------------------------------------------------------
      // Cancel failed.
      //
      // Read Firestore again because walker could have accepted
      // the request at exactly the same time.
      // --------------------------------------------------------

      final InstaWalkRequestState state =
          await _service.getRequestState(requestId);

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // Walker accepted while stop was being processed
      // --------------------------------------------------------

      if (state.isAccepted) {
        setState(() {
          _stopping = false;
        });

        _walkerAccepted(
          InstaWalkAcceptedData.fromMap(
            state.data ?? <String, dynamic>{},
          ),
        );

        _message(
          'Walker already accepted this request.',
        );

        return;
      }

      // --------------------------------------------------------
      // Request already ended
      // --------------------------------------------------------

      if (state.isExpired ||
          state.isCancelled ||
          state.status ==
              InstaWalkRequestStatus.notFound) {
        _stopTimer();
        _stopRadar();

        _requestId = null;
        _ownerPosition = null;

        setState(() {
          _searching = false;
          _searchFinished = false;
          _checkingAddress = false;
          _recovering = false;
          _secondsLeft = 0;
          _stopping = false;
        });

        _setActive(false);

        return;
      }

      // --------------------------------------------------------
      // Still searching but cancellation did not happen
      // --------------------------------------------------------

      setState(() {
        _stopping = false;
      });

      _message(
        'Unable to stop search. Please try again.',
      );
    } catch (e) {
      debugPrint(
        'Insta Walk stop search error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stopping = false;
      });

      _message(
        'Unable to stop search. Please try again.',
      );
    }
  }

  // ============================================================
  // SEARCH RECOVERY
  // ============================================================

  Future<void> _recoverSearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _recovering = false;
        _searching = false;
        _searchFinished = false;
        _checkingAddress = false;
        _secondsLeft = 0;
        _stopping = false;
      });

      _setActive(false);
      return;
    }

    try {
      final QueryDocumentSnapshot<
          Map<String, dynamic>>? ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) return;

      if (ownerDoc == null) {
        _resetSearchState();

        if (!mounted) return;

        setState(() {
          _recovering = false;
        });

        _setActive(false);
        return;
      }

      final Map<String, dynamic> ownerData =
          ownerDoc.data();

      // --------------------------------------------------------
      // PET NAME
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // OWNER ID
      // --------------------------------------------------------

      final String ownerId =
          _readFirstString(
        ownerData,
        const [
          'ownerId',
          'Owner ID',
        ],
      );

      if (ownerId.isEmpty) {
        _resetSearchState();

        if (!mounted) return;

        setState(() {
          _recovering = false;
        });

        _setActive(false);
        return;
      }

      // --------------------------------------------------------
      // FIND ACTIVE REQUEST
      // --------------------------------------------------------

      final InstaWalkRequestState? active =
          await _service.findActiveRequest(
        ownerId: ownerId,
      );

      if (!mounted) return;

      if (active == null) {
        _resetSearchState();

        if (!mounted) return;

        setState(() {
          _recovering = false;
        });

        _setActive(false);
        return;
      }

      // --------------------------------------------------------
      // SEARCHING
      // --------------------------------------------------------

      if (active.isSearching) {
        await _recoverSearchingRequest(active);
        return;
      }

      // --------------------------------------------------------
      // ACCEPTED
      // --------------------------------------------------------

      if (active.isAccepted) {
        _recoverAcceptedRequest(active);
        return;
      }

      // --------------------------------------------------------
      // OTHER / FINISHED STATE
      // --------------------------------------------------------

      _resetSearchState();

      if (!mounted) return;

      setState(() {
        _recovering = false;
      });

      _setActive(false);
    } catch (e) {
      debugPrint(
        'Insta Walk recovery error: $e',
      );

      if (!mounted) return;

      _resetSearchState();

      if (!mounted) return;

      setState(() {
        _recovering = false;
      });

      _setActive(false);
    }
  }

  // ============================================================
  // RECOVER SEARCHING REQUEST
  // ============================================================

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
      _resetSearchState();

      if (!mounted) return;

      setState(() {
        _recovering = false;
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

    // ----------------------------------------------------------
    // Already expired
    // ----------------------------------------------------------

    if (remaining.inSeconds <= 0) {
      try {
        await _service.expireRequest(
          requestId: requestId,
        );
      } catch (e) {
        debugPrint(
          'Expire recovered request error: $e',
        );
      }

      if (!mounted) return;

      _requestId = null;
      _ownerPosition = null;

      _resetSearchState();

      if (!mounted) return;

      setState(() {
        _recovering = false;
      });

      _setActive(false);
      return;
    }

    // ----------------------------------------------------------
    // Restore request
    // ----------------------------------------------------------

    _requestId = requestId;

    _ownerPosition =
        _readOwnerPosition(active.data);

    if (!mounted) return;

    setState(() {
      _recovering = false;
      _searching = true;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = remaining.inSeconds;
      _stopping = false;
    });

    _setActive(true);

    _startRadar();

    // ----------------------------------------------------------
    // Listen for walker acceptance
    // ----------------------------------------------------------

    try {
      await _service.listenForRequest(
        requestId: requestId,
        onAccepted: _walkerAccepted,
        onExpired: _finishSearch,
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
    } catch (e) {
      debugPrint(
        'Insta Walk listener setup error: $e',
      );
    }

    if (!mounted) return;

    if (_searching) {
      _startTimer();
    }
  }

  // ============================================================
  // RECOVER ACCEPTED REQUEST
  // ============================================================

  void _recoverAcceptedRequest(
    InstaWalkRequestState active,
  ) {
    final Map<String, dynamic> data =
        active.data ??
            <String, dynamic>{};

    final InstaWalkAcceptedData accepted =
        InstaWalkAcceptedData.fromMap(data);

    final String recoveredId =
        accepted.requestId.trim();

    _requestId = recoveredId.isEmpty
        ? active.requestId
        : recoveredId;

    _stopTimer();
    _stopRadar();

    if (!mounted) return;

    setState(() {
      _recovering = false;
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = 0;
      _stopping = false;
    });

    _setActive(true);

    widget.onWalkerFound?.call();
  }

  // ============================================================
  // FIND WALKER
  // ============================================================

  Future<void> _findWalker() async {
    if (_searching ||
        _checkingAddress ||
        _recovering ||
        _stopping) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('Please login first.');
      return;
    }

    if (!mounted) return;

    setState(() {
      _checkingAddress = true;
      _searchFinished = false;
    });

    try {
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

      // --------------------------------------------------------
      // OWNER ID
      // --------------------------------------------------------

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

        _message('Owner ID not found.');
        return;
      }

      // --------------------------------------------------------
      // PET NAME
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      final String address =
          _readFirstString(
        data,
        const [
          'address',
          'Adress',
          'Address',
        ],
      );

      // --------------------------------------------------------
      // ADDRESS MISSING
      // --------------------------------------------------------

      if (address.isEmpty) {
        if (!mounted) return;

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

        return;
      }

      // --------------------------------------------------------
      // OWNER NAME
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // START SEARCH
      // --------------------------------------------------------

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

  // ============================================================
  // LOCATION
  // ============================================================

  Future<Position?> _getLocation() async {
    try {
      final bool enabled =
          await Geolocator
              .isLocationServiceEnabled();

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

      return await Geolocator
          .getCurrentPosition();
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

  // ============================================================
  // START SEARCH
  // ============================================================

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

      if (!mounted) return;

      // --------------------------------------------------------
      // START FAILED
      // --------------------------------------------------------

      if (!result.success ||
          result.requestId == null ||
          result.expiresAt == null) {
        _requestId = null;

        _stopRadar();

        setState(() {
          _checkingAddress = false;
          _searching = false;
          _searchFinished = false;
          _secondsLeft = 0;
          _stopping = false;
        });

        _setActive(false);

        _message(
          result.message ??
              'Unable to start search.',
        );

        return;
      }

      final String requestId =
          result.requestId!;

      final DateTime expiresAt =
          result.expiresAt!;

      _requestId = requestId;

      Duration remaining =
          expiresAt.difference(
        DateTime.now(),
      );

      if (remaining.isNegative) {
        remaining = Duration.zero;
      }

      // --------------------------------------------------------
      // EXPIRED IMMEDIATELY
      // --------------------------------------------------------

      if (remaining.inSeconds <= 0) {
        await _service.expireRequest(
          requestId: requestId,
        );

        if (!mounted) return;

        _requestId = null;

        _resetSearchState();

        _setActive(false);

        _message(
          'Search expired. Please try again.',
        );

        return;
      }

      // --------------------------------------------------------
      // SEARCH ACTIVE
      // --------------------------------------------------------

      setState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _secondsLeft = remaining.inSeconds;
        _stopping = false;
      });

      _setActive(true);

      _startRadar();

      // --------------------------------------------------------
      // LISTENER
      // --------------------------------------------------------

      try {
        await _service.listenForRequest(
          requestId: requestId,
          onAccepted: _walkerAccepted,
          onExpired: _finishSearch,
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
      } catch (e) {
        debugPrint(
          'Insta Walk listener setup error: $e',
        );
      }

      if (!mounted) return;

      if (_searching) {
        _startTimer();
      }
    } catch (e) {
      debugPrint(
        'Insta Walk search error: $e',
      );

      if (!mounted) return;

      _stopTimer();
      _stopRadar();

      _requestId = null;

      setState(() {
        _checkingAddress = false;
        _searching = false;
        _searchFinished = false;
        _secondsLeft = 0;
        _stopping = false;
      });

      _setActive(false);

      _message(
        'Unable to start Insta Walk.',
      );
    }
  }

  // ============================================================
  // RADAR
  // ============================================================

  void _startRadar() {
    if (!mounted) return;

    if (!_radarController.isAnimating) {
      _radarController.repeat();
    }
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startTimer() {
    _stopTimer();

    if (!mounted || !_searching) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) async {
        if (!mounted || !_searching) {
          timer.cancel();
          _timer = null;
          return;
        }

        // ------------------------------------------------------
        // STOPPING
        // ------------------------------------------------------

        if (_stopping) {
          return;
        }

        final String? id = _requestId;

        if (id == null ||
            id.trim().isEmpty) {
          timer.cancel();
          _timer = null;

          _finishSearch();

          return;
        }

        // ------------------------------------------------------
        // TIMER EXPIRED
        // ------------------------------------------------------

        if (_secondsLeft <= 1) {
          timer.cancel();
          _timer = null;

          try {
            final InstaWalkRequestState state =
                await _service.getRequestState(id);

            if (!mounted) return;

            // Walker accepted exactly at expiry
            if (state.isAccepted) {
              _walkerAccepted(
                InstaWalkAcceptedData.fromMap(
                  state.data ??
                      <String, dynamic>{},
                ),
              );

              return;
            }

            // Still searching = expire it
            if (state.isSearching) {
              await _service.expireRequest(
                requestId: id,
              );
            }
          } catch (e) {
            debugPrint(
              'Insta Walk timer state error: $e',
            );
          }

          if (!mounted) return;

          _finishSearch();

          return;
        }

        // ------------------------------------------------------
        // DECREASE TIMER
        // ------------------------------------------------------

        setState(() {
          _secondsLeft--;
        });
      },
    );
  }

  // ============================================================
  // WALKER ACCEPTED
  // ============================================================

  void _walkerAccepted(
    InstaWalkAcceptedData data,
  ) {
    _stopTimer();
    _stopRadar();

    final String acceptedRequestId =
        data.requestId.trim();

    if (acceptedRequestId.isNotEmpty) {
      _requestId = acceptedRequestId;
    }

    if (!mounted) return;

    setState(() {
      _searching = false;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = 0;
      _stopping = false;
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

  // ============================================================
  // FINISH SEARCH
  // ============================================================

  void _finishSearch({
    String? message,
  }) {
    _stopTimer();
    _stopRadar();

    _requestId = null;
    _ownerPosition = null;
    _stopping = false;

    if (!mounted) return;

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

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> _retrySearch() async {
    if (_searching ||
        _checkingAddress ||
        _recovering ||
        _stopping) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _searchFinished = false;
    });

    await _findWalker();
  }

  // ============================================================
  // TIMER TEXT
  // ============================================================

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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _message(String text) {
    if (!mounted) return;

    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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

  // ============================================================
  // READ STRING
  // ============================================================

  String _readFirstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

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

  // ============================================================
  // READ OWNER POSITION
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (widget.fullScreen) {
      return _buildFullScreen();
    }

    return _buildCompactPatti();
  }
}
