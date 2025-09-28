import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Current connectivity status
  bool get isOnline => _isOnline;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    // Get initial connectivity status
    final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    _connectivityController.add(_isOnline);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        final bool wasOnline = _isOnline;
        _isOnline = _isConnected(result);
        
        if (wasOnline != _isOnline) {
          _connectivityController.add(_isOnline);
          debugPrint('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
        }
      },
    );
  }

  /// Check if any of the connectivity results indicate internet access
  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet
    );
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      _isOnline = _isConnected(result);
      return _isOnline;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
