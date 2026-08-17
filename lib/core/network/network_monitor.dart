import 'dart:async';

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
  bool _checking = true;

  final Connectivity _connectivity =
      Connectivity();

  @override
  void initState() {
    super.initState();

    _initializeNetwork();

    _subscription = _connectivity
        .onConnectivityChanged
        .listen(_handleConnectivity);
  }

  Future<void> _initializeNetwork() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();

      if (!mounted) return;

      _updateNetworkState(results);
    } catch (e) {
      debugPrint(
        'Initial connectivity check failed: $e',
      );

      if (!mounted) return;

      setState(() {
        _offline = false;
        _checking = false;
      });
    }
  }

  void _handleConnectivity(
    List<ConnectivityResult> results,
  ) {
    if (!mounted) return;

    _updateNetworkState(results);
  }

  void _updateNetworkState(
    List<ConnectivityResult> results,
  ) {
    final bool connected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.satellite ||
          result == ConnectivityResult.other,
    );

    setState(() {
      _offline = !connected;
      _checking = false;
    });
  }

  Future<void> _retry() async {
    if (!mounted) return;

    setState(() {
      _checking = true;
    });

    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();

      if (!mounted) return;

      _updateNetworkState(results);
    } catch (e) {
      debugPrint(
        'Network retry failed: $e',
      );

      if (!mounted) return;

      setState(() {
        _offline = true;
        _checking = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return widget.child;
    }

    if (_offline) {
      return NoNetworkScreen(
        onRetry: _retry,
      );
    }

    return widget.child;
  }
}
