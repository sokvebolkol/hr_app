import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/constant.dart';
import '../dashboard/approver_dashboard_screen.dart';
import '../dashboard/ceo_dashboard_screen.dart';
import '../dashboard/dashboard.dart';
import 'login-page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    await _requestPermissions();
    await _checkLogin();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // iOS: Check permissions but don't request at startup
      final permissions = <Permission>[
        Permission.camera,
        Permission.photos,
        Permission.locationWhenInUse,
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        debugPrint('iOS Permission for $permission is $status');
      }
    } else {
      // Android: Request permissions at startup
      final permissions = <Permission>[
        Permission.camera,
        Permission.photos,
        Permission.locationWhenInUse,
      ];

      for (final permission in permissions) {
        final status = await permission.request();
        debugPrint('Android Permission for $permission is $status');

        if (status.isPermanentlyDenied) {
          debugPrint(
            'Permission $permission is permanently denied. Please enable it in Settings.',
          );
          _showPermissionDialog();
        }
      }

      final storageStatus = await Permission.storage.request();
      debugPrint('Permission for storage is $storageStatus');
      if (storageStatus.isPermanentlyDenied) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Permissions Required'),
              content: const Text(
                'Some permissions are permanently denied. Please go to settings and enable them manually.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
      );
    });
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Get user role flags
      final isApprover = prefs.getBool('isApprover') ?? false;
      final isCeoUser = prefs.getBool('ceoUser') ?? false;

      // Navigate based on user role with proper error handling
      Widget targetScreen;

      if (isCeoUser) {
        targetScreen = const CeoDashboardScreen();
      } else if (isApprover) {
        targetScreen = const ApproverDashboardScreen();
      } else {
        targetScreen = const DashboardScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Chokchey HR",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Human Resource Management",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              "Loading...",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
