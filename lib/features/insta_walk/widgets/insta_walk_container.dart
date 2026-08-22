insta_walk_container.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/insta_walk_search_service.dart';

part 'insta_walk_controller.dart';
part 'insta_walk_view.dart';

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

class _InstaWalkContainerState extends State<InstaWalkContainer>
    with SingleTickerProviderStateMixin, _InstaWalkController {
  late final InstaWalkSearchService _service;

  Timer? _timer;

  late final AnimationController _radarController;

  bool _searching = false;
  bool _searchFinished = false;
  bool _checkingAddress = false;
  bool _recovering = true;

  bool _activeReported = false;

  int _secondsLeft = 0;

  String? _requestId;

  Position? _ownerPosition;

  String _petName = 'Your Pet';

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

  @override
  void dispose() {
    _stopTimer();
    _stopRadar();

    _service.dispose();
    _radarController.dispose();

    super.dispose();
  }

  void _setActive(bool active) {
    if (_activeReported == active) {
      return;
    }

    _activeReported = active;

    widget.onActiveChanged?.call(active);
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _stopRadar() {
    if (!_radarController.isAnimating &&
        _radarController.value == 0) {
      return;
    }

    _radarController.stop();
    _radarController.reset();
  }

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

  @override
  Widget build(BuildContext context) {
    if (widget.fullScreen) {
      return _buildFullScreen();
    }

    return _buildCompactPatti();
  }
}
