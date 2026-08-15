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

  bool _searching = false;
  bool _searchFinished = false;
  bool _checkingAddress = false;

  int _secondsLeft = 120;

  String? _requestId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  @override
  void dispose() {
    _timer?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }

  // =========================================================
  // FIND WALKER
  // =========================================================

  Future<void> _findWalker() async {
    if (_searching || _checkingAddress) {
      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    setState(() {
      _checkingAddress = true;
    });

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data();

      final dynamic addressValue =
          data?['address'];

      final String address =
          addressValue?.toString().trim() ?? '';

      if (!mounted) return;

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

        return;
      }

      await _startSearch(
        ownerUid: user.uid,
        address: address,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingAddress = false;
      });

      _showMessage(
        'Unable to start search. Please try again.',
      );
    }
  }

  // =========================================================
  // START SEARCH
  // =========================================================

  Future<void> _startSearch({
    required String ownerUid,
    required String address,
  }) async {
    _timer?.cancel();
    await _requestSubscription?.cancel();

    final DateTime now = DateTime.now();

    final DateTime expiresAt =
        now.add(const Duration(minutes: 2));

    try {
      final DocumentReference<Map<String, dynamic>>
          requestRef = _firestore
              .collection('walk_requests')
              .doc();

      await requestRef.set({
        'ownerUid': ownerUid,
        'address': address,
        'status': 'searching',
        'distanceKm': 3,
        'createdAt':
            FieldValue.serverTimestamp(),
        'expiresAt':
            Timestamp.fromDate(expiresAt),
        'acceptedBy': null,
        'walkerUid': null,
      });

      if (!mounted) return;

      setState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _secondsLeft = 120;
        _requestId = requestRef.id;
      });

      _listenForRequest(requestRef);

      _startTimer();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _checkingAddress = false;
      });

      _showMessage(
        'Unable to create walk request.',
      );
    }
  }

  // =========================================================
  // LISTEN FOR WALKER ACCEPT
  // =========================================================

  void _listenForRequest(
    DocumentReference<Map<String, dynamic>>
        requestRef,
  ) {
    _requestSubscription =
        requestRef.snapshots().listen(
      (snapshot) {
        if (!mounted || !snapshot.exists) {
          return;
        }

        final data = snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            data['status']?.toString() ?? '';

        if (status == 'accepted') {
          _handleWalkerAccepted(data);
        }

        if (status == 'cancelled') {
          _handleRequestCancelled();
        }

        if (status == 'expired') {
          _finishSearch();
        }
      },
    );
  }

  // =========================================================
  // WALKER ACCEPTED
  // =========================================================

  void _handleWalkerAccepted(
    Map<String, dynamic> data,
  ) {
    _timer?.cancel();
    _requestSubscription?.cancel();

    if (!mounted) return;

    setState(() {
      _searching = false;
      _searchFinished = false;
      _secondsLeft = 120;
    });

    widget.onWalkerFound?.call();

    _showMessage(
      'Walker accepted your walk request.',
    );
  }

  // =========================================================
  // REQUEST CANCELLED
  // =========================================================

  void _handleRequestCancelled() {
    _timer?.cancel();

    if (!mounted) return;

    setState(() {
      _searching = false;
      _searchFinished = true;
    });
  }

  // =========================================================
  // TIMER
  // =========================================================

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 1) {
          timer.cancel();

          await _expireRequest();

          if (!mounted) return;

          setState(() {
            _searching = false;
            _searchFinished = true;
            _secondsLeft = 0;
          });

          return;
        }

        setState(() {
          _secondsLeft--;
        });
      },
    );
  }

  // =========================================================
  // EXPIRE REQUEST
  // =========================================================

  Future<void> _expireRequest() async {
    final String? requestId = _requestId;

    if (requestId == null) {
      return;
    }

    try {
      final requestRef = _firestore
          .collection('walk_requests')
          .doc(requestId);

      final snapshot =
          await requestRef.get();

      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data();

      final String status =
          data?['status']?.toString() ?? '';

      // Don't overwrite an accepted request.
      if (status == 'searching') {
        await requestRef.update({
          'status': 'expired',
          'expiredAt':
              FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Request may already have been updated
      // by another process.
    }
  }

  // =========================================================
  // RETRY
  // =========================================================

  Future<void> _retrySearch() async {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please login first.');
      return;
    }

    await _findWalker();
  }

  // =========================================================
  // TIMER TEXT
  // =========================================================

  String _timerText() {
    final int minutes =
        (_secondsLeft ~/ 60)
            .toString()
            .padLeft(2, '0');

    final int seconds =
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
        .showSnackBar(
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
            // HEADER
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

            if (!_searching &&
                !_searchFinished)
              _findButton(),

            if (_searching)
              _searchingContainer(),

            if (_searchFinished)
              _retryContainer(),
          ],
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
        onPressed:
            _checkingAddress
                ? null
                : _findWalker,
        icon: _checkingAddress
            ? const SizedBox(
                height: 18,
                width: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Color(0xFFE45D32),
                  ),
                ),
              )
            : const Icon(
                Icons.search_rounded,
              ),
        label: Text(
          _checkingAddress
              ? 'Checking Address...'
              : 'Find a Walker',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor:
              const Color(0xFFE45D32),
          disabledBackgroundColor:
              Colors.white,
          disabledForegroundColor:
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
                  'Searching nearby online walkers. The search will continue until a walker accepts or 2 minutes are completed.',
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
  // SEARCH FINISHED
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
              'Re-search',
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
