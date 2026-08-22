part of 'insta_walk_container.dart';

mixin _InstaWalkController on State<InstaWalkContainer> {
  // ============================================================
  // SEARCH RECOVERY
  // ============================================================

  Future<void> _recoverSearch() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

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

    try {
      final QueryDocumentSnapshot<Map<String, dynamic>>? ownerDoc =
          await _service.findOwnerProfile();

      if (!mounted) return;

      if (ownerDoc == null) {
        _resetSearchState();
        return;
      }

      final Map<String, dynamic> ownerData = ownerDoc.data();

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

      final String ownerId = _readFirstString(
        ownerData,
        const [
          'ownerId',
          'Owner ID',
        ],
      );

      if (ownerId.isEmpty) {
        _resetSearchState();
        return;
      }

      final InstaWalkRequestState? active =
          await _service.findActiveRequest(
        ownerId: ownerId,
      );

      if (!mounted) return;

      if (active == null) {
        _resetSearchState();
        return;
      }

      if (active.isSearching) {
        await _recoverSearchingRequest(active);
        return;
      }

      if (active.isAccepted) {
        _recoverAcceptedRequest(active);
        return;
      }

      _resetSearchState();
    } catch (e) {
      debugPrint('Insta Walk recovery error: $e');

      if (!mounted) return;

      _resetSearchState();
    }
  }

  // ============================================================
  // RECOVER SEARCHING REQUEST
  // ============================================================

  Future<void> _recoverSearchingRequest(
    InstaWalkRequestState active,
  ) async {
    final String? requestId = active.requestId;
    final DateTime? expiresAt = active.expiresAt;

    if (requestId == null ||
        requestId.trim().isEmpty ||
        expiresAt == null) {
      _resetSearchState();
      return;
    }

    Duration remaining =
        expiresAt.difference(DateTime.now());

    if (remaining.isNegative) {
      remaining = Duration.zero;
    }

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

      _resetSearchState();
      return;
    }

    _requestId = requestId;
    _ownerPosition = _readOwnerPosition(active.data);

    if (!mounted) return;

    setState(() {
      _recovering = false;
      _searching = true;
      _searchFinished = false;
      _checkingAddress = false;
      _secondsLeft = remaining.inSeconds;
    });

    _setActive(true);
    _startRadar();

    try {
      await _service.listenForRequest(
        requestId: requestId,
        onAccepted: _walkerAccepted,
        onExpired: _finishSearch,
        onCancelled: () {
          _finishSearch(
            message: 'Walk request was cancelled.',
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
        active.data ?? <String, dynamic>{};

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
        _recovering) {
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
      final QueryDocumentSnapshot<Map<String, dynamic>>? ownerDoc =
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

      final String ownerId = _readFirstString(
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

      final String address = _readFirstString(
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
            builder: (_) => const AddressScreen(),
          ),
        );

        if (!mounted) return;

        setState(() {
          _checkingAddress = false;
        });

        return;
      }

      String ownerName = _readFirstString(
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

      if (!mounted) return;

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
          await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        _message(
          'Please turn on location service.',
        );
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
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
          expiresAt.difference(DateTime.now());

      if (remaining.isNegative) {
        remaining = Duration.zero;
      }

      if (remaining.inSeconds <= 0) {
        await _service.expireRequest(
          requestId: requestId,
        );

        if (!mounted) return;

        _resetSearchState();

        _message(
          'Search expired. Please try again.',
        );

        return;
      }

      setState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _secondsLeft = remaining.inSeconds;
      });

      _setActive(true);
      _startRadar();

      try {
        await _service.listenForRequest(
          requestId: requestId,
          onAccepted: _walkerAccepted,
          onExpired: _finishSearch,
          onCancelled: () {
            _finishSearch(
              message: 'Walk request was cancelled.',
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

            if (!mounted) return;

            if (state.isAccepted) {
              _walkerAccepted(
                InstaWalkAcceptedData.fromMap(
                  state.data ??
                      <String, dynamic>{},
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

          if (!mounted) return;

          _finishSearch();
          return;
        }

        if (!mounted) return;

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
      _recovering = false;
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

    if (!mounted) return;

    setState(() {
      _searching = false;
      _searchFinished = true;
      _checkingAddress = false;
      _secondsLeft = 0;
      _recovering = false;
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
        _recovering) {
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
        _secondsLeft < 0 ? 0 : _secondsLeft;

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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
}
