import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../constants/constant.dart';
import '../services/internet_connection_service.dart';

/// A helper class for internet connection utilities
class InternetConnectionHelper {
  /// Check internet connection and show dialog if not connected
  /// Returns true if connected, false otherwise
  static Future<bool> checkAndShowDialog(BuildContext context) async {
    final connectionService = InternetConnectionService();
    final bool isConnected = await connectionService.checkConnection();

    if (!isConnected && context.mounted) {
      InternetConnectionService.showNoInternetDialog(context);
      return false;
    }

    return true;
  }

  /// Execute a function only if internet is available
  /// Shows dialog if no internet connection
  static Future<T?> executeWithConnectionCheck<T>({
    required BuildContext context,
    required Future<T> Function() onConnected,
    Future<T?> Function()? onDisconnected,
  }) async {
    final bool isConnected = await checkAndShowDialog(context);

    if (isConnected) {
      return await onConnected();
    } else {
      return onDisconnected != null ? await onDisconnected() : null;
    }
  }

  /// Get current connection status without showing dialog
  static Future<bool> isConnected() async {
    return await InternetConnectionService().checkConnection();
  }
}

/// A widget wrapper that checks internet connection before displaying its child
class InternetAwareWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  final VoidCallback? onOffline;

  const InternetAwareWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.onOffline,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: InternetConnectionHelper.isConnected(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SpinKitCircle(color: secondary, size: 50.0),
          );
        }

        final bool isConnected = snapshot.data ?? false;

        if (!isConnected) {
          onOffline?.call();
          return offlineWidget ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No Internet Connection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please check your connection',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Trigger rebuild to check connection again
                        (context as Element).markNeedsBuild();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
        }

        return child;
      },
    );
  }
}
