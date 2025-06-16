import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'language.dart';

class LanguageLogic extends ChangeNotifier {
  Language _language = Language();
  Language get language => _language;

  int _index = 0;

  Future<void> initialize() async {
    final pref = await SharedPreferences.getInstance();
    _index = pref.getInt('languageIndex') ?? 1;
    _language = languageList[_index];
  }

  Future<void> toggleLanguage() async {
    _index++;
    if (_index >= languageList.length) _index = 0;

    _language = languageList[_index];
    notifyListeners();

    final pref = await SharedPreferences.getInstance();
    await pref.setInt('languageIndex', _index);
  }
}
