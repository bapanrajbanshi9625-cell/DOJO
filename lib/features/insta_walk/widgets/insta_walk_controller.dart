insta_walk_controller.dart

part of 'insta_walk_container.dart';

mixin _InstaWalkController on State<InstaWalkContainer> {
  Future<void> _recoverSearch() async {
    final User? user = FirebaseAuth.instance.currentUser;

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
      final QueryDocumentSnapshot<Map<String, dynamic>>? ownerDoc =
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
        await _recoverSearchingRequest(active);
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

  Future<void> _recoverSearchingRequest(
    InstaWalkRequestState active,
  ) async {
    final String? requestId = active.requestId;
    final DateTime? expiresAt = active.expiresAt;

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

    Duration remaining = expiresAt.difference(
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
        _readOwnerPosition(active.data);

    _requestId = requestId;
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
          message: 'Walk request was cancelled.',
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

  void _recoverAcceptedRequest(
    InstaWalkRequestState active,
  ) {
    final Map<String, dynamic> data = active.data ?? {};

    final InstaWalkAcceptedData accepted =
        InstaWalkAcceptedData.fromMap(data);

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

    setState(() {
      _checkingAddress = true;
      _searchFinished = false;
    });

    try {
      final QueryDocumentSnapshot<Map<String, dynamic>>? ownerDoc =
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

      final Map<String, dynamic> data = ownerDoc.data();

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

        if (!mounted) {
          return;
        }

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

      final Position? position = await _getLocation();

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

      _requestId = result.requestId;

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
        _secondsLeft = remaining.inSeconds;
      });

      _setActive(true);

      _startRadar();

      await _service.listenForRequest(
        requestId: result.requestId!,
        onAccepted: _walkerAccepted,
        onExpired: () {
          _finishSearch();
        },
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

  void _startRadar() {
    if (!mounted) {
      return;
    }

    if (!_radarController.isAnimating) {
      _radarController.repeat();
    }
  }

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

          final InstaWalkRequestState state =
              await _service.getRequestState(id);

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

    final String name = data.walkerName.trim();

    _message(
      name.isEmpty
          ? 'Walker accepted your request.'
          : '$name accepted your request.',
    );
  }

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

  String _readFirstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String result = value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }

  Position? _readOwnerPosition(
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return null;
    }

    final dynamic value = data['ownerLocation'];

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
