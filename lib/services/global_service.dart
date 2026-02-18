class ServerService {
  static final ServerService _instance = ServerService._internal();
  factory ServerService() {
    return _instance;
  }
  ServerService._internal();

  static const String prodUrl =
      'https://hr-mobile.api.chokchey.com.kh/api/'; // prod running
  static const String uatUrl =
      'http://hr-mobileapi-alb-859602875.ap-southeast-1.elb.amazonaws.com/api/'; // uat running
  static const String devUrl =
      'http://192.168.53.221:8000/api/'; // local running

  String _baseUrl = devUrl;
  String _baseUrlName = "";
  String get baseUrl => _baseUrl;
  String get baseUrlName => _baseUrlName;

  void switchToProd() {
    _baseUrl = devUrl;
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
