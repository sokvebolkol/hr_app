import 'dart:io';
import 'package:chokchey_hr_app/views/auth/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'localization/language_logic.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final languageLogic = LanguageLogic();
  await languageLogic.initialize();
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: languageLogic)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    ),
  );
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
