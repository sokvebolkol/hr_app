import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../constants/constant.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../dashboard/approver_dashboard_screen.dart';
import '../dashboard/ceo_dashboard_screen.dart';
import '../dashboard/requester_dashboard.dart';
import 'login-screen.dart';
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
    // Start periodic unread count update
    context.read<NotificationViewModel>().startPeriodicUnreadCountUpdate();
  }

  Future<void> _handleStartup() async {
    try {
      // Add timeout for the entire startup process
      await Future.wait([_checkLogin(), _requestPermissions()]).timeout(
        const Duration(seconds: 8), // Maximum 8 seconds for startup
        onTimeout: () {
          print('Startup timeout - proceeding with login check only');
          return [null, null]; // Continue anyway
        },
      );
    } catch (e) {
      print('Startup error: $e');
      // If anything fails, still proceed to login check
      await _checkLogin();
    }
  }

  Future<void> _requestPermissions() async {
    try {
      if (Platform.isIOS) {
        // iOS: Check permissions but don't request at startup
        final permissions = <Permission>[
          Permission.camera,
          Permission.photos,
          Permission.locationWhenInUse,
          Permission.notification, // Add notification permission
        ];

        for (final permission in permissions) {
          try {
            final status = await permission.status.timeout(
              const Duration(seconds: 2),
            );
            debugPrint('iOS Permission for $permission is $status');
          } catch (e) {
            debugPrint('iOS Permission check timeout for $permission: $e');
          }
        }
      } else {
        // Android: Request critical permissions only
        final criticalPermissions = <Permission>[
          Permission.notification, // Most important for your app
        ];

        final optionalPermissions = <Permission>[
          Permission.camera,
          Permission.photos,
          Permission.locationWhenInUse,
          Permission.storage,
        ];

        // Request critical permissions first (with timeout)
        for (final permission in criticalPermissions) {
          try {
            final status = await permission.request().timeout(
              const Duration(seconds: 3),
            );
            debugPrint('Critical Permission for $permission is $status');
          } catch (e) {
            debugPrint('Critical permission timeout for $permission: $e');
          }
        }

        // Request optional permissions in background (don't await)
        _requestOptionalPermissions(optionalPermissions);
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
      // Don't block startup for permission errors
    }
  }

  // Request optional permissions in background
  void _requestOptionalPermissions(List<Permission> permissions) async {
    for (final permission in permissions) {
      try {
        final status = await permission.request().timeout(
          const Duration(seconds: 2),
        );
        debugPrint('Optional Permission for $permission is $status');

        if (status.isPermanentlyDenied) {
          debugPrint(
            'Permission $permission is permanently denied. Will show dialog when needed.',
          );
          // Don't show dialog immediately - wait for user action
        }
      } catch (e) {
        debugPrint('Optional permission timeout for $permission: $e');
      }
    }
  }

  Future<void> _checkLogin() async {
    try {
      // Minimum splash time for branding (reduced from 1 second)
      await Future.delayed(const Duration(milliseconds: 800));

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        // Get user role flags
        final isApprover = prefs.getBool('isApprover') ?? false;
        final isCeoUser = prefs.getBool('ceoUser') ?? false;

        print(
          '🔐 User logged in - Role: ${isCeoUser
              ? 'CEO'
              : isApprover
              ? 'Approver'
              : 'Requester'}',
        );

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
        print('🔓 No valid token - redirecting to login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('Login check error: $e');
      // If anything fails, go to login screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            // Animated title
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Text(
                      "Chokchey HR",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
