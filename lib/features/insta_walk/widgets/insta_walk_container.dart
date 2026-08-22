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
import 'insta_walk_searching.dart';
import '../../../screens/address_screen.dart';

part 'insta_walk_find_walker.dart';
part 'insta_walk_start_search.dart';
part 'insta_walk_stop_search.dart';
part 'insta_walk_recovery.dart';
part 'insta_walk_walker_accepted.dart';

part 'insta_walk_view.dart';

// ============================================================
// INSTA WALK CONTAINER
// ============================================================

class InstaWalkContainer extends StatefulWidget {
  final VoidCallback? onWalkerFound;

  final ValueChanged<bool>? onActiveChanged;

  final bool fullScreen;

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
  // SAFE STATE UPDATE
  //
  // IMPORTANT:
  // Extensions cannot directly call protected setState().
  // All insta_walk extensions should use _updateState().
  // ==========================================================

  void _updateState(VoidCallback callback) {
    if (!mounted) {
      return;
    }

    setState(callback);
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

  // ==========================================================
  // TIMER
  // ==========================================================

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

        if (_stopping) {
          return;
        }

        final String? id = _requestId;

        if (id == null || id.trim().isEmpty) {
          timer.cancel();
          _timer = null;

          _finishSearch();
          return;
        }

        if (_secondsLeft <= 1) {
          timer.cancel();
          _timer = null;

          try {
            final InstaWalkRequestState state =
                await _service.getRequestState(id);

            if (!mounted) {
              return;
            }

            if (state.isAccepted) {
              _walkerAccepted(
                InstaWalkAcceptedData.fromMap(
                  state.data ?? <String, dynamic>{},
                ),
              );

              return;
            }

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

          if (!mounted) {
            return;
          }

          _finishSearch();
          return;
        }

        _updateState(() {
          _secondsLeft--;
        });
      },
    );
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
  // FINISH SEARCH
  // ==========================================================

  void _finishSearch({
    String? message,
  }) {
    _stopTimer();
    _stopRadar();

    _requestId = null;
    _ownerPosition = null;
    _stopping = false;

    if (!mounted) {
      return;
    }

    _updateState(() {
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
        _recovering ||
        _stopping) {
      return;
    }

    if (!mounted) {
      return;
    }

    _updateState(() {
      _searchFinished = false;
    });

    await _findWalker();
  }

  // ==========================================================
  // TIMER TEXT
  // ==========================================================

  String _timerText() {
    final int safeSeconds =
        _secondsLeft < 0 ? 0 : _secondsLeft;

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
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ==========================================================
  // READ STRING
  // ==========================================================

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

  // ==========================================================
  // READ OWNER POSITION
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
}
