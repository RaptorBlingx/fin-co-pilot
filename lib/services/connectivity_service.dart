import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Lightweight reactive connectivity monitor.
class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isOnline = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;

  /// Start listening to connectivity changes.
  void init() {
    _connectivity.checkConnectivity().then(_update);
    _sub = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (isOnline.value != online) {
      isOnline.value = online;
      if (kDebugMode) {
        debugPrint('🌐 Connectivity: ${online ? "online" : "offline"}');
      }
    }
  }

  void dispose() {
    _sub?.cancel();
    isOnline.dispose();
  }
}
