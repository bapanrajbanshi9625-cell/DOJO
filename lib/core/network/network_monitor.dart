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
  bool _checking = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _checkInternet();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivity);
  }

  // ============================================================
  // CHECK INTERNET
  // ============================================================

  Future<void> _checkInternet() async {
    if (_checking) return;

    if (mounted) {
      setState(() {
        _checking = true;
      });
    }

    try {
      final bool internetAvailable =
          await _hasInternet();

      if (!mounted) return;

      setState(() {
        _offline = !internetAvailable;
      });
    } catch (e) {
      debugPrint(
        'Network monitor error: $e',
      );

      if (!mounted) return;

      setState(() {
        _offline = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  // ============================================================
  // REAL INTERNET CHECK
  // ============================================================

  Future<bool> _hasInternet() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity()
              .checkConnectivity();

      final bool connected =
          results.any(
        (result) =>
            result ==
                ConnectivityResult.mobile ||
            result ==
                ConnectivityResult.wifi ||
            result ==
                ConnectivityResult.ethernet ||
            result ==
                ConnectivityResult.vpn,
      );

      if (!connected) {
        return false;
      }

      // --------------------------------------------------------
      // REAL INTERNET TEST
      // --------------------------------------------------------

      final List<InternetAddress> addresses =
          await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(
        const Duration(seconds: 5),
      );

      return addresses.isNotEmpty &&
          addresses.first.rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint(
        'Internet check failed: $e',
      );

      return false;
    }
  }

  // ============================================================
  // CONNECTIVITY CHANGE
  // ============================================================

  Future<void> _handleConnectivity(
    List<ConnectivityResult> results,
  ) async {
    // Network state changed.
    // Check the actual internet again.
    await _checkInternet();
  }

  // ============================================================
  // RETRY BUTTON
  // ============================================================

  Future<void> _retry() async {
    if (_checking) return;

    await _checkInternet();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;

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
        onRetry: _retry,
      );
    }

    // ----------------------------------------------------------
    // INTERNET AVAILABLE
    // ----------------------------------------------------------

    return widget.child;
  }
}
