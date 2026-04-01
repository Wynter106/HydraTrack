import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription? _subscription;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Check current status
    final result = await Connectivity().checkConnectivity();
    _isOnline = _hasConnection(result);
    notifyListeners();

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      final online = _hasConnection(result);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
