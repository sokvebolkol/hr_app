import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localization/language_logic.dart';
import 'constants/constant.dart';
import 'viewmodels/nofitication_viewmodel.dart';
import 'views/auth/splash-screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_notification_service.dart';
import 'test_firebase_simple.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    HttpOverrides.global = MyHttpOverrides();

    await _requestPermissions();

    // Initialize Firebase with options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Initialize notification service
    await FirebaseNotificationService().initialize();
    print('✅ Notification service initialized');

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
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chokchey HR',
      routes: {'/firebase-test': (context) => const SimpleFirebaseTest()},
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
      final permissions = <Permission>[
        Permission.camera,
        Permission.photos,
        Permission.locationWhenInUse,
        Permission.notification,
      ];

      for (final permission in permissions) {
        final status = await permission.request();
        debugPrint('Android Permission for $permission is $status');

        if (status.isPermanentlyDenied) {
          debugPrint(
            'Permission $permission is permanently denied. Please enable it in Settings.',
          );
        }
      }

      final storageStatus = await Permission.storage.request();
      debugPrint('Permission for storage is $storageStatus');
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
