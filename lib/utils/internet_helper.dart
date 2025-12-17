import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_alert_dialog.dart';

class InternetHelper {
  /// Check if device has internet connection
  static Future<bool> hasInternet() async {
    try {
      // First check connectivity
      final connectivityResults = await Connectivity().checkConnectivity();

      if (connectivityResults.contains(ConnectivityResult.none)) {
        return false;
      }

      // Then check actual internet access
      return await InternetConnectionChecker.instance.hasConnection;
    } catch (e) {
      debugPrint('Error checking internet: $e');
      return false;
    }
  }

  /// Check internet and show alert if not connected
  /// Returns true if connected, false if no internet
  static Future<bool> checkAndAlert(
    BuildContext context, {
    String? title,
    String? message,
    bool useDialog = true,
  }) async {
    final hasConnection = await hasInternet();

    if (!hasConnection && context.mounted) {
      if (useDialog) {
        await CustomAlertDialog.show(
          context,
          title: title ?? 'No Internet Connection',
          message:
              message ?? 'Please check your internet connection and try again',
          icon: Icons.wifi_off,
          iconColor: primary,
          primaryButtonText: 'Retry',
          secondaryButtonText: 'OK',
          onPrimaryPressed: () async {
            Navigator.of(context).pop();
            await checkAndAlert(context);
          },
          onSecondaryPressed: () => Navigator.of(context).pop(),
        );
      } else {
        _showNoInternetSnackbar(
          context,
          message: message ?? 'No internet connection',
        );
      }
    }

    return hasConnection;
  }

  /// Show no internet snackbar
  static void _showNoInternetSnackbar(
    BuildContext context, {
    required String message,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.signal_wifi_off, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => checkAndAlert(context, useDialog: false),
        ),
      ),
    );
  }
}
