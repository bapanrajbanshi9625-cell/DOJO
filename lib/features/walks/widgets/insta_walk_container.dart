import 'dart:async';
import 'package:flutter/material.dart';

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

  int _secondsLeft = 300;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSearch() {
    if (_searching) return;

    _timer?.cancel();

    setState(() {
      _searching = true;
      _searchFinished = false;
      _secondsLeft = 300;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsLeft <= 1) {
          timer.cancel();

          setState(() {
            _searching = false;
            _searchFinished = true;
          });

          return;
        }

        setState(() {
          _secondsLeft--;
        });
      },
    );
  }

  void _retrySearch() {
    _startSearch();
  }

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

            // =================================================
            // NORMAL STATE
            // =================================================

            if (!_searching &&
                !_searchFinished)
              _findButton(),

            // =================================================
            // SEARCHING STATE
            // =================================================

            if (_searching)
              _searchingContainer(),

            // =================================================
            // FINISHED STATE
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
        onPressed: _startSearch,
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
                  'Searching nearby online walkers. The search will continue until a walker accepts or 5 minutes are completed.',
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
