import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../screens/address_screen.dart';

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
    extends State<InstaWalkContainer> {
  Timer? _timer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  bool _checkingSearch = true;
  bool _searching = false;
  bool _searchFinished = false;

  bool _cancelEnabled = false;
  bool _cancelling = false;

  int _secondsLeft = 0;

  String? _requestId;

  DocumentReference<Map<String, dynamic>>?
      get _requestRef {
    final id = _requestId;

    if (id == null || id.isEmpty) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection('walk_requests')
        .doc(id);
  }

  @override
  void initState() {
    super.initState();
    _restoreSearch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }

  // =========================================================
  // RESTORE EXISTING SEARCH
  // =========================================================

  Future<void> _restoreSearch() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _checkingSearch = false;
        });
      }
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('walk_requests')
          .where(
            'ownerUid',
            isEqualTo: user.uid,
          )
          .where(
            'status',
            whereIn: ['searching'],
          )
          .limit(1)
          .get();

      if (!mounted) return;

      if (query.docs.isEmpty) {
        setState(() {
          _checkingSearch = false;
          _searching = false;
          _searchFinished = false;
        });
        return;
      }

      final doc = query.docs.first;

      _requestId = doc.id;

      setState(() {
        _checkingSearch = false;
        _searching = true;
        _searchFinished = false;
      });

      _listenToRequest(doc.reference);
      _updateTimerFromFirestore(doc.data());
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _checkingSearch = false;
      });
    }
  }

  // =========================================================
  // FIND WALKER
  // =========================================================

  Future<void> _findWalker() async {
    if (_searching || _checkingSearch) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    setState(() {
      _checkingSearch = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      final address = data?['address'];

      final hasAddress =
          address is String &&
          address.trim().isNotEmpty;

      if (!hasAddress) {
        if (!mounted) return;

        setState(() {
          _checkingSearch = false;
        });

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddressScreen(),
          ),
        );

        if (!mounted) return;

        // Address screen से वापस आने के बाद
        // फिर से Firestore check होगा।
        final updatedUserDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        final updatedAddress =
            updatedUserDoc.data()?['address'];

        final saved =
            updatedAddress is String &&
            updatedAddress.trim().isNotEmpty;

        if (!saved) {
          return;
        }

        // Address save हो गया है।
        // User को खुद Find a Walker फिर दबाना होगा।
        _showMessage(
          'Address saved. Tap Find a Walker again.',
        );

        return;
      }

      await _createSearchRequest(user.uid);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _checkingSearch = false;
      });

      _showMessage(
        'Unable to check your address.',
      );
    }
  }

  // =========================================================
  // CREATE SEARCH REQUEST
  // =========================================================

  Future<void> _createSearchRequest(
    String ownerUid,
  ) async {
    _timer?.cancel();
    await _requestSubscription?.cancel();

    final now = DateTime.now();

    final expiresAt =
        Timestamp.fromDate(
      now.add(
        const Duration(minutes: 2),
      ),
    );

    final requestRef = FirebaseFirestore
        .instance
        .collection('walk_requests')
        .doc();

    await requestRef.set({
      'ownerUid': ownerUid,
      'status': 'searching',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt,
      'searchRadiusKm': 3,
    });

    if (!mounted) return;

    _requestId = requestRef.id;

    setState(() {
      _checkingSearch = false;
      _searching = true;
      _searchFinished = false;
      _cancelEnabled = false;
      _cancelling = false;
      _secondsLeft = 120;
    });

    _listenToRequest(requestRef);

    _startLocalTimer();
  }

  // =========================================================
  // FIRESTORE LISTENER
  // =========================================================

  void _listenToRequest(
    DocumentReference<Map<String, dynamic>> ref,
  ) {
    _requestSubscription?.cancel();

    _requestSubscription = ref.snapshots().listen(
      (snapshot) {
        if (!mounted || !snapshot.exists) return;

        final data = snapshot.data();

        if (data == null) return;

        final status =
            data['status']?.toString();

        // Walker future में accept करेगा।
        if (status == 'accepted') {
          _timer?.cancel();

          setState(() {
            _searching = false;
            _searchFinished = false;
          });

          widget.onWalkerFound?.call();
          return;
        }

        // Owner cancelled.
        if (status == 'cancelled') {
          _timer?.cancel();

          setState(() {
            _searching = false;
            _searchFinished = true;
          });

          return;
        }

        // Search expired.
        if (status == 'expired') {
          _timer?.cancel();

          setState(() {
            _searching = false;
            _searchFinished = true;
            _secondsLeft = 0;
          });

          return;
        }

        if (status == 'searching') {
          _updateTimerFromFirestore(data);
        }
      },
    );
  }

  // =========================================================
  // FIRESTORE EXPIRES AT
  // =========================================================

  void _updateTimerFromFirestore(
    Map<String, dynamic> data,
  ) {
    final expiresAt = data['expiresAt'];

    if (expiresAt is! Timestamp) {
      return;
    }

    final remaining =
        expiresAt.toDate().difference(
              DateTime.now(),
            );

    final seconds =
        remaining.inSeconds.clamp(0, 120);

    if (!mounted) return;

    setState(() {
      _secondsLeft = seconds;
      _cancelEnabled = seconds <= 60;
    });

    if (seconds <= 0) {
      _expireRequest();
      return;
    }

    _startLocalTimer();
  }

  // =========================================================
  // DISPLAY TIMER
  // =========================================================

  void _startLocalTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 0) {
          timer.cancel();
          await _expireRequest();
          return;
        }

        setState(() {
          _secondsLeft--;

          // Exactly 60 seconds remaining:
          // Cancel becomes enabled.
          _cancelEnabled =
              _secondsLeft <= 60;
        });

        if (_secondsLeft <= 0) {
          timer.cancel();
          await _expireRequest();
        }
      },
    );
  }

  // =========================================================
  // EXPIRE REQUEST
  // =========================================================

  Future<void> _expireRequest() async {
    final ref = _requestRef;

    if (ref == null) return;

    try {
      final snapshot = await ref.get();

      if (!snapshot.exists) return;

      final status =
          snapshot.data()?['status']?.toString();

      // Do not overwrite accepted/cancelled.
      if (status != 'searching') return;

      await ref.update({
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Firestore listener will handle the final state.
    }
  }

  // =========================================================
  // CANCEL SEARCH
  // =========================================================

  Future<void> _cancelSearch() async {
    if (!_searching ||
        !_cancelEnabled ||
        _cancelling) {
      return;
    }

    final ref = _requestRef;

    if (ref == null) return;

    setState(() {
      _cancelling = true;
    });

    try {
      final snapshot = await ref.get();

      if (!snapshot.exists) return;

      final status =
          snapshot.data()?['status']?.toString();

      if (status != 'searching') {
        return;
      }

      await ref.update({
        'status': 'cancelled',
        'cancelledAt':
            FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _cancelling = false;
      });

      _showMessage(
        'Unable to cancel search.',
      );
    }
  }

  // =========================================================
  // RETRY
  // =========================================================

  Future<void> _retrySearch() async {
    setState(() {
      _searchFinished = false;
      _checkingSearch = false;
      _secondsLeft = 0;
      _cancelEnabled = false;
    });

    await _findWalker();
  }

  // =========================================================
  // TIMER TEXT
  // =========================================================

  String _timerText() {
    final minutes =
        (_secondsLeft ~/ 60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        (_secondsLeft % 60)
            .toString()
            .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // =========================================================
  // BUILD
  // =========================================================

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
              Color(0xFFE45D32),
              Color(0xFFC84A24),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(.08),
              blurRadius: 18,
              offset:
                  const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // HEADER
            // =================================================

            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(.18),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.white,
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
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Find a walker right now',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              'We search for an online and available walker within 3 km.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            if (_checkingSearch)
              _checkingContainer()
            else if (!_searching &&
                !_searchFinished)
              _findButton()
            else if (_searching)
              _searchingContainer()
            else
              _retryContainer(),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CHECKING
  // =========================================================

  Widget _checkingContainer() {
    return const SizedBox(
      width: double.infinity,
      height: 50,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor:
              AlwaysStoppedAnimation<Color>(
            Colors.white,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FIND BUTTON
  // =========================================================

  Widget _findButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _findWalker,
        icon: const Icon(
          Icons.search_rounded,
        ),
        label: const Text(
          'Find a Walker',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor:
              const Color(0xFFE45D32),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SEARCHING
  // =========================================================

  Widget _searchingContainer() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(
              height: 20,
              width: 20,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<
                        Color>(
                  Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Text(
                'Searching for a walker...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),

            Text(
              _timerText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(.13),
            borderRadius:
                BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Searching nearby online walkers. Search remains active until a walker accepts, you cancel it, or 2 minutes expire.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Text(
          _cancelEnabled
              ? 'You can cancel the search now.'
              : 'Cancel becomes available at 01:00.',
          style: TextStyle(
            color:
                Colors.white.withOpacity(.80),
            fontSize: 10,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed:
                _cancelEnabled && !_cancelling
                    ? _cancelSearch
                    : null,
            icon: _cancelling
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.close_rounded,
                  ),
            label: Text(
              _cancelling
                  ? 'Cancelling...'
                  : _cancelEnabled
                      ? 'Cancel Search'
                      : 'Cancel Search • Locked',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            style:
                OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor:
                  Colors.white38,
              side: BorderSide(
                color: _cancelEnabled
                    ? Colors.white
                    : Colors.white30,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'Maximum search distance: 3 km',
          style: TextStyle(
            color:
                Colors.white.withOpacity(.75),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FINISHED
  // =========================================================

  Widget _retryContainer() {
    return Column(
      children: [
        const Row(
          children: [
            Icon(
              Icons.person_search_rounded,
              color: Colors.white,
              size: 21,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No walker accepted the request',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _retrySearch,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: const Text(
              'Retry Search',
              style: TextStyle(
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.black,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
