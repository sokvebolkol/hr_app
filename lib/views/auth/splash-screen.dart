import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:chokchey_hr_app/views/dashboard/manager_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../dashboard/ceo_dashboard_screen.dart';
import '../dashboard/requester_dashboard.dart';
import '../leaves/leave_request/leave_request_screen.dart';
import '../../viewmodels/profile_viewmodel.dart';
import 'login-screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../utils/internet_helper.dart';
import '../../widgets/device_integrity_guard.dart';
import 'welcome.dart';

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
      // Check internet connection first
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Brief delay for splash

      if (mounted) {
        final hasInternet = await InternetHelper.checkAndAlert(context);
        if (!hasInternet) {
          debugPrint(
            'No internet connection - proceeding with limited functionality',
          );
        }
      }

      // Add timeout for the entire startup process
      await Future.wait([_checkLogin(), _requestPermissions()]).timeout(
        const Duration(seconds: 8), // Maximum 8 seconds for startup
        onTimeout: () {
          debugPrint('Startup timeout - proceeding with login check only');
          return [null, null]; // Continue anyway
        },
      );
    } catch (e) {
      debugPrint('Startup error: $e');
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

      // Advisory warning on rooted / jailbroken devices. Shown once per app
      // launch, before routing, so it appears for every role and for the
      // login path too. The user acknowledges and continues; nothing is
      // restricted.
      if (mounted) {
        await DeviceIntegrityGuard.showLaunchWarningIfNeeded(context);
      }
      if (!mounted) return;

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
          targetScreen = const ManagerDashboard();
        } else {
          targetScreen = const RequesterDashboardScreen();
        }

        // Capture the navigator before the splash route is replaced so the
        // follow-up push doesn't rely on this (about to be removed) context.
        final navigator = Navigator.of(context);
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => targetScreen),
        );

        // Honour the user's landing screen preference. If they chose "Leave",
        // open the Leave Request form on top of their dashboard so the back
        // button returns them to the dashboard. Defaults to Dashboard.
        final landingScreenIndex =
            prefs.getInt('landingScreenIndex') ?? kLandingScreenDashboard;
        if (landingScreenIndex == kLandingScreenLeave) {
          navigator.push(
            MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
          );
        }
      } else {
        print('🔓 No valid token - redirecting to login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } catch (e) {
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
      backgroundColor: Colors.grey.shade100,
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
                        'assets/images/logo_256x256.png',
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
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
                      "CHOKCHEY",
                      style: TextStyle(
                        color: secondary,
                        fontSize: 26,
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
