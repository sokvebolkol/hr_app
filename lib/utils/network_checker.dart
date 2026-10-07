import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'exceptions.dart';

/// Utility class to check network connectivity
class NetworkChecker {
  static final Connectivity _connectivity = Connectivity();

  /// Check if device has network interface connectivity (WiFi/Mobile data)
  static Future<bool> hasNetworkInterface() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      // If connectivity check fails, fallback to internet check
      return true;
    }
  }

  /// Check if device has actual internet connection (can reach external servers)
  static Future<bool> hasInternetConnection({
    List<String> hosts = const ['google.com', '1.1.1.1', '8.8.8.8'],
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      // Try multiple hosts for reliability
      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host).timeout(timeout);
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (_) {
          continue;
        }
      }
      return false;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Comprehensive connectivity check (both network interface and internet)
  static Future<bool> hasConnection({
    bool checkInterface = true,
    bool checkInternet = true,
  }) async {
    if (checkInterface) {
      final hasInterface = await hasNetworkInterface();
      if (!hasInterface) return false;
    }

    if (checkInternet) {
      return await hasInternetConnection();
    }

    return true;
  }

  /// Check connectivity and throw exception if no connection
  /// Use this before making API calls
  static Future<void> checkConnectivity() async {
    final hasInternet = await hasConnection();
    if (!hasInternet) {
      throw NetworkException(
        message:
            'No internet connection. Please check your network and try again.',
      );
    }
  }

  /// Stream to listen for connectivity changes
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

}
