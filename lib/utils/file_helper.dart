import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/constant.dart';
import '../localization/language.dart';
import '../localization/language_logic.dart';
import '../services/global_service.dart';
import '../widgets/custom_toast_message.dart';

class FileHelper {
  final _fileName = "counter.txt";

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<File> writeCounter(int counter) async {
    final file = await _localFile;
    return file.writeAsString('$counter');
  }

  Future<int> readCounter() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      return int.parse(contents);
    } catch (e) {
      return 0;
    }
  }

  // Dollar formatter function
  static String toDollarSyntax(double number) {
    return "\$ ${number.toStringAsFixed(2)}";
  }

  // Convert Dollar to Riel
  static String toRielSyntax(double dollarAmount) {
    double exchangeRate = 4100.0;
    double rielAmount = dollarAmount * exchangeRate;
    return "៛ ${rielAmount.toStringAsFixed(2)}";
  }

  // Phone number format
  static String formatPhoneNumber(String phoneNumber) {
    final formattedNumber = StringBuffer();
    if (phoneNumber.length >= 3) {
      formattedNumber.write(phoneNumber.substring(0, 3));
      formattedNumber.write('-');
    }
    if (phoneNumber.length >= 6) {
      formattedNumber.write(phoneNumber.substring(3, 6));
      formattedNumber.write('-');
    }
    formattedNumber.write(phoneNumber.substring(6));

    return formattedNumber.toString();
  }

  // Abbreviate Name
  static String abbreviateName(String fullName) {
    List<String> nameParts = fullName.split(' ');

    if (nameParts.length < 2) {
      if (fullName.isNotEmpty) {
        return fullName[0].toUpperCase();
      } else {
        return '';
      }
    }

    String abbreviation = '';

    for (int i = 0; i < nameParts.length; i++) {
      String part = nameParts[i];
      if (part.isNotEmpty) {
        abbreviation += part[0].toUpperCase();
        if (abbreviation.length >= 2) {
          break;
        }
      }
    }

    return abbreviation;
  }

  // DateFormat.MMM() gives Jan, Feb, etc.
  String getMonthShortName(int month) {
    return DateFormat.MMM().format(DateTime(0, month));
  }

  /**
   * Get current date by format Day Date Month, Year for En
   */
  String getCurrentDayEn() {
    var now = DateTime.now();
    var formatter = DateFormat('EEEE d MMMM y');
    return formatter.format(now);
  }

  /**
   * Get current date by format Day Date Month, Year for Kh
   */
  String getCurrentDayKh() {
    initializeDateFormatting('km', null);
    var now = DateTime.now();
    var formatter = DateFormat('d MMMM y', 'km');
    return formatter.format(now);
  }

  /**
   * Date format
   */
  static formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String formatTime(String? time) {
    if (time == null || time.isEmpty || time == '00:00') {
      return '--:--';
    }
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = timeParts[1];

      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time;
    }
  }

  /**
   * Get color based on leave status
   * @param status: Leave status as a string
   * @return Color: Corresponding color for the status
   * Example: statusColor(status: "Approved") returns Colors.green
   */
  static Color statusColor({required String status}) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      case "Pending":
        return logoPink;
      case "Cancelled":
        return Colors.grey;
      default:
        return Colors.orangeAccent;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case '0':
        return 'Rejected';
      case '1':
        return 'Approved';
      case '2':
        return 'Pending';
      case '3':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case '0' || 'Rejected': // Rejected
        return Icons.cancel_outlined;
      case '1' || 'Approved': // Approved
        return Icons.check_circle_outline;
      case '2' || 'Pending': // Pending
        return Icons.hourglass_empty;
      case '3' || 'Cancelled': // Cancelled
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  static getStatusColor(String status) {
    switch (status) {
      case '0' || 'Rejected':
        return Colors.red;
      case '1' || 'Approved':
        return Colors.green;
      case '2' || 'Pending':
        return Colors.orange;
      case '3' || 'Cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Computed properties
  Future<String> getGreeting() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    final Language language = languageLogic.language;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return language.goodMorning;
    } else if (hour < 18) {
      return language.goodAfternoon;
    } else {
      return language.goodEvening;
    }
  }

  Color getLeaveTypeColor(String? leaveType) {
    if (leaveType == null) return secondary;

    switch (leaveType.toLowerCase()) {
      case 'annual leave':
        return secondary;
      case 'sick leave':
        return const Color(0xFFFF9800); // Orange
      case 'special leave':
        return const Color(0xFF9C27B0); // Purple
      case 'maternity leave':
        return const Color(0xFF4CAF50); // Green
      case 'unpaid leave':
        return const Color(0xFF607D8B); // Blue Grey
      default:
        return secondary;
    }
  }

  // Version comparison
  // Return true if currentVersion is older than latestVersion

  static bool isVersionOlder(String currentVersion, String latestVersion) {
    List<String> currentParts = currentVersion.split('.');
    List<String> latestParts = latestVersion.split('.');

    for (int i = 0; i < latestParts.length; i++) {
      int currentPart = int.parse(currentParts[i]);
      int latestPart = int.parse(latestParts[i]);

      if (currentPart < latestPart) {
        return true;
      } else if (currentPart > latestPart) {
        return false;
      }
    }
    return false;
  }

  static void showUpdateDialog(BuildContext context, String latestVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            "Update Required",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, size: 60, color: secondary),
              const SizedBox(height: 20),
              Text(
                "Version $latestVersion is available. Please update to continue using the app.",
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  String url = '';

                  // Check platform and set the appropriate update URL
                  if (Platform.isIOS) {
                    url = getIosUpdateUrl;
                  } else if (Platform.isAndroid) {
                    url = getAndroidUpdateUrl;
                  }

                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    print('Could not launch $url');
                  }
                },
                child: const Text(
                  "Update Now",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ Add GlobalKey for navigator access
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ✅ FIXED: Network monitoring with proper context handling
  static bool _isConnected = true;
  static bool _wasDisconnected = false;
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  static void monitorNetworkStatus(BuildContext? context) {
    print('🌐 Starting network monitoring...');

    // Cancel existing subscription if any
    _connectivitySubscription?.cancel();

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        print('📡 Connectivity changed: $results');

        bool isConnected = results.any(
          (result) => result != ConnectivityResult.none,
        );

        print(
          '📊 Current state: isConnected=$isConnected, _isConnected=$_isConnected',
        );

        // ✅ Connection restored
        if (isConnected && !_isConnected) {
          print('✅ Connection restored!');
          _isConnected = true;
          _wasDisconnected = false;

          final ctx = _getValidContext(context);
          if (ctx != null) {
            showCustomToast(
              ctx,
              "Connected",
              "You are now connected to the internet.",
              Colors.green,
              Icons.wifi,
            );

            // Auto dismiss after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              _removeCustomToast();
            });
          }
        }
        // ✅ Connection lost
        else if (!isConnected && _isConnected) {
          print('❌ Connection lost!');
          _isConnected = false;
          _wasDisconnected = true;

          final ctx = _getValidContext(context);
          if (ctx != null) {
            showCustomToast(
              ctx,
              "No Connection",
              "Please check your internet connection and try again.",
              Colors.redAccent,
              Icons.wifi_off,
            );
          }
        }
      },
      onError: (error) {
        print('❌ Connectivity error: $error');
      },
    );

    // ✅ Check initial connectivity state
    Connectivity().checkConnectivity().then((results) {
      _isConnected = results.any((result) => result != ConnectivityResult.none);
      print('🔍 Initial connectivity: $_isConnected, results: $results');

      if (!_isConnected) {
        final ctx = _getValidContext(context);
        if (ctx != null) {
          showCustomToast(
            ctx,
            "No Connection",
            "Please check your internet connection.",
            Colors.redAccent,
            Icons.wifi_off,
          );
        }
      }
    });
  }

  // ✅ Helper method to get valid context
  static BuildContext? _getValidContext(BuildContext? context) {
    // Try provided context first
    if (context != null && context.mounted) {
      try {
        Overlay.of(context);
        return context;
      } catch (e) {
        print('⚠️ Provided context has no overlay: $e');
      }
    }

    // Fallback to navigator key
    if (_navigatorKey?.currentContext != null) {
      final navContext = _navigatorKey!.currentContext!;
      try {
        Overlay.of(navContext);
        return navContext;
      } catch (e) {
        print('⚠️ Navigator context has no overlay: $e');
      }
    }

    print('❌ No valid context with Overlay found');
    return null;
  }

  // ✅ Dispose network monitoring
  static void disposeNetworkMonitoring() {
    print('🛑 Stopping network monitoring...');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  static OverlayEntry? _currentOverlayEntry;

  static void showCustomToast(
    BuildContext context,
    String title,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    print('📢 Showing toast: $title - $message');

    try {
      _removeCustomToast();

      final overlay = Overlay.of(context);
      _currentOverlayEntry = OverlayEntry(
        builder:
            (context) => Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: CustomToast(
                  title: title,
                  message: message,
                  backgroundColor: backgroundColor,
                  icon: icon,
                  onActionPressed: () {
                    _removeCustomToast();
                  },
                ),
              ),
            ),
      );

      overlay.insert(_currentOverlayEntry!);

      // Don't auto-dismiss "No Connection" toast
      if (title == "Connected") {
        Future.delayed(const Duration(seconds: 3), () {
          _removeCustomToast();
        });
      }
    } catch (e) {
      print('❌ Error showing toast: $e');
    }
  }

  static void _removeCustomToast() {
    try {
      print('🗑️ Removing toast');
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    } catch (e) {
      print('⚠️ Error removing toast: $e');
    }
  }

  // ✅ FIXED: Server monitoring with proper context handling
  static Timer? _serverMonitoringTimer;
  static bool _serverWasDown = false;

  static void monitorServerStatus(BuildContext? context) async {
    print('🖥️ Starting server monitoring...');

    // Initial check
    await _checkServerStatus(context);

    // Cancel existing timer if any
    _serverMonitoringTimer?.cancel();

    // Check server status every 30 seconds
    _serverMonitoringTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkServerStatus(context),
    );
  }

  static Future<void> _checkServerStatus(BuildContext? context) async {
    try {
      print('🔍 Checking server status...');
      final response = await http
          .get(Uri.parse(ServerService().baseUrl))
          .timeout(const Duration(seconds: 10));

      print('📡 Server response: ${response.statusCode}');

      // If server was down and now it's up
      if (_serverWasDown && response.statusCode == 404) {
        print('✅ Server is back online!');
        _serverWasDown = false;
        _removeCustomToastServerError();
      }
    } catch (e) {
      print('❌ Server check failed: $e');

      if (!_serverWasDown) {
        print('🚨 Server is down!');
        _serverWasDown = true;

        // ✅ Use valid context
        final ctx = _getValidContext(context);
        if (ctx != null) {
          // Use addPostFrameCallback to ensure widget tree is ready
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showCustomToastServerError(
              ctx,
              "Server Under Maintenance",
              "The server is currently unavailable. Please try again later.",
              Colors.orange,
              Icons.cloud_off,
            );
          });
        } else {
          print('⚠️ Cannot show server error toast - no valid context');
        }
      }
    }
  }

  // ✅ Dispose server monitoring
  static void disposeServerMonitoring() {
    print('🛑 Stopping server monitoring...');
    _serverMonitoringTimer?.cancel();
    _serverMonitoringTimer = null;
  }

  static OverlayEntry? _currentOverlayEntryServerError;

  static void showCustomToastServerError(
    BuildContext context,
    String title,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    print('📢 Showing server error toast: $title');

    try {
      _removeCustomToastServerError();

      final overlay = Overlay.of(context);
      _currentOverlayEntryServerError = OverlayEntry(
        builder:
            (context) => Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: CustomToast(
                  title: title,
                  message: message,
                  backgroundColor: backgroundColor,
                  icon: icon,
                  onActionPressed: () {
                    _removeCustomToastServerError();
                  },
                ),
              ),
            ),
      );

      overlay.insert(_currentOverlayEntryServerError!);
    } catch (e) {
      print('❌ Error showing server error toast: $e');
    }
  }

  static void _removeCustomToastServerError() {
    try {
      print('🗑️ Removing server error toast');
      _currentOverlayEntryServerError?.remove();
      _currentOverlayEntryServerError = null;
    } catch (e) {
      print('⚠️ Error removing server error toast: $e');
    }
  }
}
