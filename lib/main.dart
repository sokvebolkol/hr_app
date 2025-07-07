import 'dart:io';
import 'package:chokchey_hr_app/views/auth/login-page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'localization/language_logic.dart';
import 'constants/constant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageLogic = LanguageLogic();
  await languageLogic.initialize();
  HttpOverrides.global = MyHttpOverrides();

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
      title: 'Chokchey HR App',
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
      home: const LoginScreen(),
    );
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
