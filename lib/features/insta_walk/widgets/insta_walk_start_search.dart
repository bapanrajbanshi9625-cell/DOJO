part of 'insta_walk_container.dart';

// ============================================================
// START SEARCH
// ============================================================

extension _StartSearchRole on _InstaWalkContainerState {
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

        _updateState(() {
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

      _updateState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _secondsLeft = remaining.inSeconds;
        _stopping = false;
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

      _updateState(() {
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
}
