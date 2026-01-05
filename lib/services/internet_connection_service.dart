import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class InternetConnectionService {
  static final InternetConnectionService _instance =
      InternetConnectionService._internal();

  factory InternetConnectionService() => _instance;

  InternetConnectionService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker =
      InternetConnectionChecker.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _internetSubscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Callback for connection status changes
  Function(bool)? onConnectionChanged;

  /// Initialize the service and start listening to connectivity changes
  Future<void> initialize() async {
    // Check initial connection
    _isConnected = await _internetChecker.hasConnection;
    print('🌐 Initial internet connection: $_isConnected');

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });

    // Listen to internet connection status changes
    _internetSubscription = _internetChecker.onStatusChange.listen((
      InternetConnectionStatus status,
    ) {
      _handleInternetStatusChange(status);
    });
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool hasConnection =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    print('📶 Connectivity changed: $results, hasConnection: $hasConnection');

    // Check actual internet connection
    _checkInternetConnection();
  }

  /// Handle internet status changes
  void _handleInternetStatusChange(InternetConnectionStatus status) {
    final bool connected = status == InternetConnectionStatus.connected;
    print('🌐 Internet status changed: $status, connected: $connected');

    if (_isConnected != connected) {
      _isConnected = connected;
      onConnectionChanged?.call(_isConnected);
    }
  }

  /// Check actual internet connection
  Future<bool> _checkInternetConnection() async {
    try {
      final bool hasConnection = await _internetChecker.hasConnection;
      if (_isConnected != hasConnection) {
        _isConnected = hasConnection;
        onConnectionChanged?.call(_isConnected);
      }
      return hasConnection;
    } catch (e) {
      print('❌ Error checking internet connection: $e');
      return false;
    }
  }

  /// Manually check internet connection
  Future<bool> checkConnection() async {
    return await _checkInternetConnection();
  }

  /// Show no internet dialog
  static void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red[700], size: 30),
              const SizedBox(width: 10),
              const Text(
                'No Internet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please check your internet connection and try again.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                '• Check if Wi-Fi or mobile data is enabled\n'
                '• Try turning airplane mode on and off\n'
                '• Restart your router',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Check connection again
                final hasConnection =
                    await InternetConnectionService().checkConnection();
                if (!hasConnection && context.mounted) {
                  // Show dialog again if still no connection
                  showNoInternetDialog(context);
                }
              },
              child: const Text(
                'Retry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  /// Dispose subscriptions
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
  }
}
