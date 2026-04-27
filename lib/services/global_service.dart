import 'package:shared_preferences/shared_preferences.dart';

enum Environment { development, uat, production }

class ServerService {
  static final ServerService _instance = ServerService._internal();
  factory ServerService() {
    return _instance;
  }
  ServerService._internal();

  static const String prodUrl =
      'https://hr-mobile.api.chokchey.com.kh/api/'; // prod running
  static const String uatUrl =
      'https://uat-coapp.chokchey.com.kh/api/'; // uat running
  static const String devUrl =
      'http://192.168.53.73:8000/api/'; // local running

  static const String _envKey = 'selected_environment';

  String _baseUrl = prodUrl;
  String _baseUrlName = "Production";
  Environment _currentEnvironment = Environment.production;

  String get baseUrl => _baseUrl;
  String get baseUrlName => _baseUrlName;
  Environment get currentEnvironment => _currentEnvironment;

  /// Initialize the service and load saved environment
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEnv = prefs.getString(_envKey);

    if (savedEnv != null) {
      switch (savedEnv) {
        case 'production':
          _setEnvironment(Environment.production, saveToPrefs: false);
          break;
        case 'uat':
          _setEnvironment(Environment.uat, saveToPrefs: false);
          break;
        case 'development':
          _setEnvironment(Environment.development, saveToPrefs: false);
          break;
      }
    }
  }

  /// Internal method to set environment
  void _setEnvironment(Environment env, {bool saveToPrefs = true}) {
    _currentEnvironment = env;
    switch (env) {
      case Environment.production:
        _baseUrl = prodUrl;
        _baseUrlName = "Production";
        break;
      case Environment.uat:
        _baseUrl = uatUrl;
        _baseUrlName = "UAT";
        break;
      case Environment.development:
        _baseUrl = devUrl;
        _baseUrlName = "Development";
        break;
    }
    print("🌐 Environment: $_baseUrlName\n📡 Base URL: $_baseUrl");

    if (saveToPrefs) {
      _saveEnvironment(env);
    }
  }

  /// Save environment to shared preferences
  Future<void> _saveEnvironment(Environment env) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_envKey, env.name);
  }

  /// Switch to Production environment
  Future<void> switchToProd() async {
    _setEnvironment(Environment.production);
  }

  /// Switch to UAT environment
  Future<void> switchToUat() async {
    _setEnvironment(Environment.uat);
  }

  /// Switch to Development environment
  Future<void> switchToDev() async {
    _setEnvironment(Environment.development);
  }

  /// Switch to any environment
  Future<void> switchToEnvironment(Environment env) async {
    _setEnvironment(env);
  }

  /// Clear all user session data when switching environments
  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();

    // Get environment setting before clearing
    final savedEnv = prefs.getString(_envKey);

    // Clear all data
    await prefs.clear();

    // Restore environment setting
    if (savedEnv != null) {
      await prefs.setString(_envKey, savedEnv);
    }

    print('🔐 User session cleared for environment switch');
  }
}

final baseUrl = ServerService().baseUrl;
