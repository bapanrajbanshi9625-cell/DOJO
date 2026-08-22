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

part 'insta_walk_controller.dart';
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
