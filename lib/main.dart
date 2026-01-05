import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localization/language_logic.dart';
import 'constants/constant.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'views/auth/splash-screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_notification_service.dart';
import 'services/internet_connection_service.dart';
import 'firebase_options.dart';

/// Check if device has internet connection
/// Returns true if connected, false otherwise
Future<bool> checkInternetConnection() async {
  try {
    final result = await InternetAddress.lookup(
      'google.com',
    ).timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  } on TimeoutException catch (_) {
    return false;
  } catch (_) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    HttpOverrides.global = MyHttpOverrides();

    // Check internet connection before Firebase initialization
    final hasInternet = await checkInternetConnection();
    if (hasInternet) {
      print('✅ Internet connection available');
    } else {
      print('⚠️ No internet connection - app will run in offline mode');
    }

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
    final notificationService = FirebaseNotificationService();
    await notificationService.initialize().timeout(const Duration(seconds: 10));
    print('✅ Notification service initialized');

    // Add this debug call
    await notificationService.debugNotificationStatus();
  } catch (e) {
    print('⚠️ Firebase initialization failed or timed out: $e');
    print('📱 App will continue without Firebase features');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final InternetConnectionService _connectionService =
      InternetConnectionService();

  @override
  void initState() {
    super.initState();
    _setupConnectionListener();
  }

  void _setupConnectionListener() {
    _connectionService.onConnectionChanged = (bool isConnected) {
      if (!isConnected && mounted) {
        // Show no internet dialog when connection is lost
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            InternetConnectionService.showNoInternetDialog(context);
          }
        });
      }
    };
  }

  @override
  void dispose() {
    _connectionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chokchey HR',
      theme: ThemeData(
        fontFamily: 'Roboto',
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

// Make permissions non-blocking but more explicit for iOS
Future<void> _requestPermissions() async {
  try {
    if (Platform.isIOS) {
      print('📱 Requesting iOS permissions...');

      // Request notification permission explicitly
      final notificationStatus = await Permission.notification.request();
      print('📋 iOS Notification permission: $notificationStatus');

      final permissions = <Permission>[
        Permission.camera,
        Permission.photos,
        Permission.locationWhenInUse,
      ];

      for (final permission in permissions) {
        final status = await permission.status;
        debugPrint('📋 iOS Permission for $permission is $status');

        if (status.isDenied) {
          debugPrint(
            '⚠️ iOS Permission $permission is denied, will request when needed',
          );
        }
      }
    } else {
      // Android permissions
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
          debugPrint('📋 Android Permission for $permission is $status');

          if (status.isPermanentlyDenied) {
            debugPrint(
              '❌ Permission $permission is permanently denied. Please enable it in Settings.',
            );
          }
        } catch (e) {
          debugPrint('⏰ Permission request timeout for $permission: $e');
        }
      }

      try {
        final storageStatus = await Permission.storage.request().timeout(
          const Duration(seconds: 3),
        );
        debugPrint('📋 Permission for storage is $storageStatus');
      } catch (e) {
        debugPrint('⏰ Storage permission timeout: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ Error requesting permissions: $e');
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
