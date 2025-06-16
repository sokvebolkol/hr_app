import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/language.dart';
import '../../localization/language_logic.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Language language = Language();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    language = context.watch<LanguageLogic>().language;
    return Scaffold(
      body: Center(
        child: Image(
          image: const AssetImage('assets/images/logo.png'),
          width: screenWidth / 2,
        ),
      ),
    );
  }
}
