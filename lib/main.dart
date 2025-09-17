import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localization/language_logic.dart';
import 'constants/constant.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'views/auth/splash-screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_notification_service.dart';
import 'firebase_options.dart';
import 'views/notifications/notifcation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    HttpOverrides.global = MyHttpOverrides();

    // Initialize Firebase with timeout
    await _initializeFirebaseWithTimeout();

    // Request permissions after Firebase (non-blocking)
    _requestPermissions(); // Remove await to make it non-blocking

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: languageLogic),
          ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    print('❌ Error initializing app: $e');
    // Still run the app even if Firebase fails
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageLogic()),
          ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ],
        child: const MyApp(),
      ),
    );
  }
}

// Add timeout for Firebase initialization
Future<void> _initializeFirebaseWithTimeout() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10)); // 10 second timeout

    print('✅ Firebase initialized successfully');

    // Initialize notification service with timeout
    await FirebaseNotificationService().initialize().timeout(
      const Duration(seconds: 5),
    );
    print('✅ Notification service initialized');
  } catch (e) {
    print('⚠️ Firebase initialization failed or timed out: $e');
    print('📱 App will continue without Firebase features');
    // Don't throw error - let app continue
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chokchey HR',
      routes: {
        '/notifications': (context) => const NotificationScreen(),
      },
      theme: ThemeData(
        fontFamily: 'times',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primary, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Make permissions non-blocking
Future<void> _requestPermissions() async {
  try {
    if (Platform.isIOS) {
      final permissions = <Permission>[
        Permission.camera,
        Permission.photos,
        Permission.locationWhenInUse,
        Permission.notification,
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        debugPrint('iOS Permission for $permission is $status');

        if (status.isDenied) {
          debugPrint(
            'iOS Permission $permission is denied, will request when needed',
          );
        }
      }
    } else {
      // Request permissions in background for Android
      final permissions = <Permission>[
        Permission.camera,
        Permission.photos,
        Permission.locationWhenInUse,
        Permission.notification,
      ];

      for (final permission in permissions) {
        try {
          final status = await permission.request().timeout(
            const Duration(seconds: 3),
          );
          debugPrint('Android Permission for $permission is $status');

          if (status.isPermanentlyDenied) {
            debugPrint(
              'Permission $permission is permanently denied. Please enable it in Settings.',
            );
          }
        } catch (e) {
          debugPrint('Permission request timeout for $permission: $e');
        }
      }

      try {
        final storageStatus = await Permission.storage.request().timeout(
          const Duration(seconds: 3),
        );
        debugPrint('Permission for storage is $storageStatus');
      } catch (e) {
        debugPrint('Storage permission timeout: $e');
      }
    }
  } catch (e) {
    debugPrint('Error requesting permissions: $e');
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
