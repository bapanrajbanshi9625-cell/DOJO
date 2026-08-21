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
  late final InstaWalkSearchService _service;

  Timer? _timer;

  late final AnimationController _radarController;

  bool _searching = false;
  bool _searchFinished = false;
  bool _checkingAddress = false;

  int _secondsLeft = 0;

  String? _requestId;

  Position? _ownerPosition;

  Duration _currentDuration =
      InstaWalkSearchService.firstSearchDuration;

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
    _timer?.cancel();
    _service.dispose();
    _radarController.dispose();
    super.dispose();
  }

  // ==========================================================
  // RECOVER
  // ==========================================================

  Future<void> _recoverSearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    // Existing active request recovery can be
    // added here without changing UI.
  }

  // ==========================================================
  // FIND WALKER
  // ==========================================================

  Future<void> _findWalker() async {
    if (_searching || _checkingAddress) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('Please login first.');
      return;
    }

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

      final String ownerId =
          data['ownerId']?.toString().trim() ?? '';

      if (ownerId.isEmpty) {
        setState(() {
          _checkingAddress = false;
        });

        _message('Owner ID not found.');
        return;
      }

      String address =
          data['address']?.toString().trim() ?? '';

      if (address.isEmpty) {
        address =
            data['Adress']?.toString().trim() ?? '';
      }

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

        if (mounted) {
          setState(() {
            _checkingAddress = false;
          });
        }

        return;
      }

      String ownerName =
          data['fullName']?.toString().trim() ?? '';

      if (ownerName.isEmpty) {
        ownerName =
            data['Full Name']?.toString().trim() ?? '';
      }

      if (ownerName.isEmpty) {
        ownerName = 'Dog Owner';
      }

      final Position? position =
          await _getLocation();

      if (!mounted || position == null) {
        if (mounted) {
          setState(() {
            _checkingAddress = false;
          });
        }
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
      debugPrint('Insta Walk error: $e');

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
    } catch (_) {
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

    _requestId = result.requestId;

    _currentDuration =
        result.duration ??
        const Duration(minutes: 2);

    setState(() {
      _checkingAddress = false;
      _searching = true;
      _searchFinished = false;
      _secondsLeft =
          _currentDuration.inSeconds;
    });

    _radarController.repeat();

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
    );

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
        if (!mounted || !_searching) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 1) {
          timer.cancel();

          final String? id = _requestId;

          if (id != null) {
            await _service.expireRequest(
              requestId: id,
            );
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
  // ACCEPTED
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
    });

    widget.onWalkerFound?.call();

    _message(
      data.walkerName.isEmpty
          ? 'Walker accepted your request.'
          : '${data.walkerName} accepted your request.',
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

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        8,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF243746),
              Color(0xFF304E5A),
              Color(0xFF376A70),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF65D6C8)
                .withValues(alpha: .18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: .10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _header(),

            const SizedBox(height: 15),

            Text(
              _searching
                  ? 'Searching available walkers near your current location.'
                  : 'Find an available walker nearby instantly.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 16),

            if (!_searching && !_searchFinished)
              InstaWalkSearchButton(
                loading: _checkingAddress,
                text: _checkingAddress
                    ? 'Checking location...'
                    : 'Find a Walker Now',
                onPressed: _checkingAddress
                    ? null
                    : _findWalker,
              ),

            if (_searching &&
                _ownerPosition != null)
              InstaWalkSearching(
                timerText: _timerText(),
                map: InstaWalkMapRadar(
                  ownerPoint: LatLng(
                    _ownerPosition!.latitude,
                    _ownerPosition!.longitude,
                  ),
                  searchRadiusKm:
                      InstaWalkSearchService
                          .searchRadiusKm,
                  radarAnimation:
                      _radarController,
                ),
              ),

            if (_searchFinished)
              InstaWalkRetry(
                onRetry: _retrySearch,
              ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF65D6C8),
                Color(0xFF8FFFEF),
              ],
            ),
            borderRadius:
                BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF65D6C8)
                    .withValues(alpha: .25),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(
            Icons.flash_on_rounded,
            color: Color(0xFF243746),
            size: 29,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Insta Walk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Find a walker right now',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF65D6C8)
                .withValues(alpha: .12),
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF65D6C8)
                  .withValues(alpha: .25),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: Color(0xFF65D6C8),
                size: 8,
              ),
              SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Color(0xFF8FFFEF),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
