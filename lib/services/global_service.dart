class ServerService {
  static final ServerService _instance = ServerService._internal();
  factory ServerService() {
    return _instance;
  }
  ServerService._internal();

  static const String prodUrl =
      'http://192.168.111.23:2004/api/'; // prod running
  static const String uatUrl = 'http://192.168.111.23:2004/api/'; // uat running
  static const String devUrl = 'http://192.168.1.15:8000/api/'; // local running

  String _baseUrl = devUrl;
  String _baseUrlName = "";
  String get baseUrl => _baseUrl;
  String get baseUrlName => _baseUrlName;

  void switchToProd() {
    _baseUrl = prodUrl;
    _baseUrlName = "Production";
    print("Switch to Production $_baseUrl");
  }

  void switchToUat() {
    _baseUrl = uatUrl;
    _baseUrlName = "UAT";
    print("Switch to UAT $_baseUrl");
  }

  void switchToDev() {
    _baseUrl = devUrl;
    _baseUrlName = "Local Development";
    print("Switch to Dev $_baseUrl");
  }
}

final baseUrl = ServerService().baseUrl;
