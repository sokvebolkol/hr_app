import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'localization/language_logic.dart';
import 'constants/constant.dart';
import 'views/auth/splash-screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageLogic = LanguageLogic();
  await languageLogic.initialize();
  HttpOverrides.global = MyHttpOverrides();

  await _requestPermissions();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: languageLogic)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            backgroundColor: Theme.of(context).colorScheme.primary,
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
  final permissions = <Permission>[
    Permission.camera,
    Permission.photos, // iOS: read access to photos
    Permission.locationWhenInUse,
  ];

  for (final permission in permissions) {
    final status = await permission.request();
    debugPrint('Permission for $permission is $status');

    if (status.isPermanentlyDenied) {
      debugPrint(
        'Permission $permission is permanently denied. Please enable it in Settings.',
      );
    }
  }

  if (Platform.isAndroid) {
    final storageStatus = await Permission.storage.request();
    debugPrint('Permission for storage is $storageStatus');
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
