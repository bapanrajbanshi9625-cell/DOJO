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
  State<NetworkMonitor> createState() => _NetworkMonitorState();
}

class _NetworkMonitorState extends State<NetworkMonitor> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _offline = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();

    _checkInternet();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivity);
  }

  Future<void> _checkInternet() async {
    if (_checking) return;

    _checking = true;

    try {
      final result = await _hasInternet();

      if (!mounted) return;

      setState(() {
        _offline = !result;
      });
    } finally {
      _checking = false;
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();

      final bool connected = results.any(
        (item) =>
            item == ConnectivityResult.mobile ||
            item == ConnectivityResult.wifi ||
            item == ConnectivityResult.ethernet ||
            item == ConnectivityResult.vpn,
      );

      if (!connected) {
        return false;
      }

      final List<InternetAddress> lookup =
          await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(
        const Duration(seconds: 5),
      );

      return lookup.isNotEmpty &&
          lookup.first.rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Network check failed: $e');
      return false;
    }
  }

  Future<void> _handleConnectivity(
    List<ConnectivityResult> results,
  ) async {
    await _checkInternet();
  }

  Future<void> _retry() async {
    if (_checking) return;

    setState(() {
      _checking = true;
    });

    final bool internetAvailable =
        await _hasInternet();

    if (!mounted) return;

    setState(() {
      _offline = !internetAvailable;
      _checking = false;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_offline) {
      return NoNetworkScreen(
        onRetry: _retry,
      );
    }

    return widget.child;
  }
}
