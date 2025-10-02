import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localization/language_logic.dart';
import 'constants/constant.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'views/auth/splash-screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    HttpOverrides.global = MyHttpOverrides();
    _requestPermissions();

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
    print('Error initializing app: $e');
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chokchey HR',
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
          debugPrint('Android Permission for $permission is $status');

          if (status.isPermanentlyDenied) {
            debugPrint(
              'Permission $permission is permanently denied. Please enable it in Settings.',
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
