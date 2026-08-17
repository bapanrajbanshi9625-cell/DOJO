import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../screens/no_network_screen.dart';

class NetworkMonitor extends StatefulWidget {
  final Widget child;

  const NetworkMonitor({
    super.key,
    required this.child,
  });

  @override
  State<NetworkMonitor> createState() =>
      _NetworkMonitorState();
}

class _NetworkMonitorState
    extends State<NetworkMonitor> {
  StreamSubscription<List<ConnectivityResult>>?
      _subscription;

  bool _offline = false;

  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // INITIAL INTERNET CHECK
    // ----------------------------------------------------------

    _checkInternet();

    // ----------------------------------------------------------
    // LISTEN FOR NETWORK CHANGES
    // ----------------------------------------------------------

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivity);
  }

  // ============================================================
  // INITIAL / NORMAL INTERNET CHECK
  // ============================================================

  Future<void> _checkInternet() async {
    final bool result =
        await _hasInternet();

    if (!mounted) {
      return;
    }

    setState(() {
      _offline = !result;
    });
  }

  // ============================================================
  // ACTUAL INTERNET CHECK
  // ============================================================

  Future<bool> _hasInternet() async {
    try {
      final List<ConnectivityResult> result =
          await Connectivity()
              .checkConnectivity();

      // --------------------------------------------------------
      // CHECK NETWORK CONNECTION TYPE
      // --------------------------------------------------------

      final bool connected =
          result.any(
        (item) =>
            item ==
                ConnectivityResult.mobile ||
            item ==
                ConnectivityResult.wifi ||
            item ==
                ConnectivityResult.ethernet ||
            item ==
                ConnectivityResult.vpn,
      );

      if (!connected) {
        return false;
      }

      // --------------------------------------------------------
      // CHECK REAL INTERNET ACCESS
      // --------------------------------------------------------
      //
      // Connectivity alone does not guarantee internet.
      // Therefore we also perform DNS lookup.
      //
      // --------------------------------------------------------

      final List<InternetAddress> lookup =
          await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(
        const Duration(
          seconds: 5,
        ),
      );

      return lookup.isNotEmpty &&
          lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CONNECTIVITY CHANGE
  // ============================================================

  Future<void> _handleConnectivity(
    List<ConnectivityResult> results,
  ) async {
    final bool internetAvailable =
        await _hasInternet();

    if (!mounted) {
      return;
    }

    setState(() {
      _offline = !internetAvailable;
    });
  }

  // ============================================================
  // RETRY BUTTON
  // ============================================================

  Future<void> _retryInternet() async {
    // ----------------------------------------------------------
    // PREVENT DOUBLE TAP
    // ----------------------------------------------------------

    if (_isRetrying) {
      return;
    }

    if (mounted) {
      setState(() {
        _isRetrying = true;
      });
    }

    // ----------------------------------------------------------
    // CHECK INTERNET AGAIN
    // ----------------------------------------------------------

    final bool internetAvailable =
        await _hasInternet();

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // UPDATE SCREEN
    // ----------------------------------------------------------

    setState(() {
      _offline = !internetAvailable;
      _isRetrying = false;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ----------------------------------------------------------
    // NO INTERNET
    // ----------------------------------------------------------

    if (_offline) {
      return NoNetworkScreen(
        onRetry: _retryInternet,
      );
    }

    // ----------------------------------------------------------
    // INTERNET AVAILABLE
    // ----------------------------------------------------------

    return widget.child;
  }
}
