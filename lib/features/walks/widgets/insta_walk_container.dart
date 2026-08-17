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

  static const String _ownerProfilesCollection =
      'ownerProfiles';

  static const String _walkRequestsCollection =
      'walk_requests';

  static const double _searchDistanceKm = 3.0;

  // =========================================================
  // DISPOSE
  // =========================================================

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

    if (!mounted) {
      return;
    }

    setState(() {
      _checkingAddress = true;
      _searchFinished = false;
    });

    try {
      // =====================================================
      // IMPORTANT
      //
      // ownerProfiles document ID is:
      // OWN26GM0001
      //
      // Firebase UID is stored inside:
      // authUid
      //
      // Therefore DON'T use:
      //
      // .doc(user.uid)
      //
      // We search using authUid field.
      // =====================================================

      final QuerySnapshot<Map<String, dynamic>>
          ownerQuery = await _firestore
              .collection(_ownerProfilesCollection)
              .where(
                'authUid',
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

      if (!mounted) {
        return;
      }

      // =====================================================
      // OWNER PROFILE NOT FOUND
      // =====================================================

      if (ownerQuery.docs.isEmpty) {
        setState(() {
          _checkingAddress = false;
        });

        _showMessage(
          'Owner profile not found. Please complete your profile.',
        );

        return;
      }

      // =====================================================
      // OWNER DOCUMENT
      // =====================================================

      final QueryDocumentSnapshot<Map<String, dynamic>>
          ownerDoc = ownerQuery.docs.first;

      final Map<String, dynamic> ownerData =
          ownerDoc.data();

      // =====================================================
      // OWNER ID
      //
      // Example:
      // ownerId = OWN26GM0001
      //
      // Document ID is also OWN26GM0001,
      // but we intentionally use the field.
      // =====================================================

      final String ownerId =
          ownerData['ownerId']?.toString().trim() ?? '';

      if (ownerId.isEmpty) {
        setState(() {
          _checkingAddress = false;
        });

        _showMessage(
          'Owner ID not found. Please complete your owner profile.',
        );

        return;
      }

      // =====================================================
      // OWNER ADDRESS
      // =====================================================

      final String address =
          ownerData['address']?.toString().trim() ?? '';

      // =====================================================
      // ADDRESS EMPTY
      // =====================================================

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

        // ===================================================
        // ADDRESS SCREEN SE RETURN KE BAAD
        // PROFILE DOBARA CHECK KARO
        // ===================================================

        await _findWalker();

        return;
      }

      // =====================================================
      // OWNER NAME
      // =====================================================

      String ownerName =
          ownerData['fullName']?.toString().trim() ?? '';

      if (ownerName.isEmpty) {
        ownerName = 'Dog Owner';
      }

      // =====================================================
      // START WALKER SEARCH
      // =====================================================

      await _startSearch(
        ownerId: ownerId,
        ownerAuthUid: user.uid,
        ownerName: ownerName,
        address: address,
      );
    } catch (e) {
      debugPrint(
        'Insta Walk owner profile error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingAddress = false;
      });

      _showMessage(
        'Unable to check owner profile. Please try again.',
      );
    }
  }

  // =========================================================
  // START SEARCH
  // =========================================================

  Future<void> _startSearch({
    required String ownerId,
    required String ownerAuthUid,
    required String ownerName,
    required String address,
  }) async {
    _timer?.cancel();

    await _requestSubscription?.cancel();

    final DateTime now = DateTime.now();

    final DateTime expiresAt =
        now.add(
      const Duration(minutes: 2),
    );

    try {
      // =====================================================
      // CREATE WALK REQUEST
      // =====================================================

      final DocumentReference<Map<String, dynamic>>
          requestRef = _firestore
              .collection(_walkRequestsCollection)
              .doc();

      await requestRef.set({
        // ===================================================
        // OWNER
        // ===================================================

        'ownerId': ownerId,

        'ownerAuthUid': ownerAuthUid,

        'ownerName': ownerName,

        // ===================================================
        // ADDRESS
        // ===================================================

        'address': address,

        // ===================================================
        // SEARCH
        // ===================================================

        'status': 'searching',

        'distanceKm': _searchDistanceKm,

        // ===================================================
        // TIMESTAMP
        // ===================================================

        'createdAt':
            FieldValue.serverTimestamp(),

        'expiresAt':
            Timestamp.fromDate(expiresAt),

        // ===================================================
        // ACCEPTANCE
        // ===================================================

        'acceptedBy': null,

        'walkerId': null,
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingAddress = false;
        _searching = true;
        _searchFinished = false;
        _secondsLeft = 120;
        _requestId = requestRef.id;
      });

      // =====================================================
      // LISTEN
      // =====================================================

      _listenForRequest(requestRef);

      // =====================================================
      // TIMER
      // =====================================================

      _startTimer();
    } catch (e) {
      debugPrint(
        'Create walk request error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _checkingAddress = false;
        _searching = false;
      });

      _showMessage(
        'Unable to create walk request. Please try again.',
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
    _requestSubscription?.cancel();

    _requestSubscription =
        requestRef.snapshots().listen(
      (DocumentSnapshot<Map<String, dynamic>>
          snapshot) {
        if (!mounted || !snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            data['status']?.toString().trim() ?? '';

        // ===================================================
        // ACCEPTED
        // ===================================================

        if (status == 'accepted') {
          _handleWalkerAccepted(data);
          return;
        }

        // ===================================================
        // CANCELLED
        // ===================================================

        if (status == 'cancelled') {
          _handleRequestCancelled();
          return;
        }

        // ===================================================
        // EXPIRED
        // ===================================================

        if (status == 'expired') {
          _finishSearch();
          return;
        }
      },
      onError: (Object error) {
        debugPrint(
          'Walk request listener error: $error',
        );
      },
    );
  }

  // =========================================================
  // FINISH SEARCH
  // =========================================================

  void _finishSearch() {
    _timer?.cancel();
    _requestSubscription?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _searchFinished = true;
      _secondsLeft = 0;
    });
  }

  // =========================================================
  // WALKER ACCEPTED
  // =========================================================

  void _handleWalkerAccepted(
    Map<String, dynamic> data,
  ) {
    _timer?.cancel();
    _requestSubscription?.cancel();

    if (!mounted) {
      return;
    }

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
    _requestSubscription?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _searching = false;
      _searchFinished = true;
      _secondsLeft = 0;
    });

    _showMessage(
      'Walk request was cancelled.',
    );
  }

  // =========================================================
  // TIMER
  // =========================================================

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (!_searching) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 1) {
          timer.cancel();

          await _expireRequest();

          if (!mounted) {
            return;
          }

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

    if (requestId == null ||
        requestId.trim().isEmpty) {
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>>
          requestRef = _firestore
              .collection(_walkRequestsCollection)
              .doc(requestId);

      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await requestRef.get();

      if (!snapshot.exists) {
        return;
      }

      final Map<String, dynamic>? data =
          snapshot.data();

      final String status =
          data?['status']?.toString().trim() ?? '';

      // =====================================================
      // IMPORTANT
      //
      // Accepted request ko expired nahi karna.
      // =====================================================

      if (status == 'searching') {
        await requestRef.update({
          'status': 'expired',
          'expiredAt':
              FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint(
        'Expire walk request error: $e',
      );
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

    if (!mounted) {
      return;
    }

    setState(() {
      _searchFinished = false;
    });

    await _findWalker();
  }

  // =========================================================
  // TIMER TEXT
  // =========================================================

  String _timerText() {
    final String minutes =
        (_secondsLeft ~/ 60)
            .toString()
            .padLeft(2, '0');

    final String seconds =
        (_secondsLeft % 60)
            .toString()
            .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
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
              offset: const Offset(0, 7),
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

            // =================================================
            // DESCRIPTION
            // =================================================

            const Text(
              'We search for an online and available walker within 3 km.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // =================================================
            // FIND
            // =================================================

            if (!_searching &&
                !_searchFinished)
              _findButton(),

            // =================================================
            // SEARCHING
            // =================================================

            if (_searching)
              _searchingContainer(),

            // =================================================
            // FINISHED
            // =================================================

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
        onPressed: _checkingAddress
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
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SEARCHING UI
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
  // SEARCH FINISHED UI
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
          child:
              ElevatedButton.icon(
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
            style:
                ElevatedButton.styleFrom(
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
