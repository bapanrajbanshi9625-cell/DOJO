part of 'insta_walk_container.dart';

// ============================================================
// SEARCH RECOVERY
// ============================================================

extension _RecoveryRole on _InstaWalkContainerState {
  Future<void> _recoverSearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      _updateState(() {
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

        _updateState(() {
          _recovering = false;
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
        _resetSearchState();

        if (!mounted) return;

        _updateState(() {
          _recovering = false;
        });

        _setActive(false);
        return;
      }

      final InstaWalkRequestState? active =
          await _service.findActiveRequest(
        ownerId: ownerId,
      );

      if (!mounted) return;

      if (active == null) {
        _resetSearchState();

        if (!mounted) return;

        _updateState(() {
          _recovering = false;
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

      if (!mounted) return;

      _updateState(() {
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

      _updateState(() {
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

      _updateState(() {
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

      _updateState(() {
        _recovering = false;
      });

      _setActive(false);
      return;
    }

    _requestId = requestId;

    _ownerPosition =
        _readOwnerPosition(active.data);

    if (!mounted) return;

    _updateState(() {
      _recovering = false;
      _searching = true;
      _searchFinished = false;
      _checkingAddress = false;
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

    _updateState(() {
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
}
