// Prefixed so `async.TimeoutException` (thrown by .timeout()) is distinct
// from the app's own `TimeoutException` in exceptions.dart.
import 'dart:async' as async;
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/exceptions.dart';
import '../utils/error_handler.dart';
import '../utils/network_checker.dart';
import 'global_service.dart';

/// HTTP service wrapper with built-in error handling.
///
/// Load-related behaviour (to avoid flooding the backend):
/// - The internet + `GET /server-checking` pre-check runs once per app
///   launch per server. After it succeeds, later requests skip it. A failed
///   check is not cached, so the next request (e.g. the user tapping Retry)
///   checks again. Switching environment changes the base URL and therefore
///   triggers a fresh check.
/// - Concurrent callers of the same pre-check share one call.
/// - Identical GETs already in flight (same URL and same token) are shared
///   instead of being sent twice.
/// - Requests time out after 15 seconds and surface an error the UI can
///   offer a Retry for. Nothing here retries automatically.
class HttpService {
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _serverCheckTimeout = Duration(seconds: 5);

  /// Base URL that passed the pre-check during this app launch.
  static String? _verifiedBaseUrl;

  /// Pre-check currently running, shared by concurrent callers.
  static Future<void>? _serverCheckInFlight;
  static String? _serverCheckInFlightUrl;

  /// Identical GETs currently in flight, keyed by URL + Authorization.
  static final Map<String, Future<http.Response>> _inFlightGets = {};

  /// Forget the cached pre-check, so the next request checks again.
  static void resetServerCheck() {
    _verifiedBaseUrl = null;
    _serverCheckInFlight = null;
    _serverCheckInFlightUrl = null;
  }

  /// Internet + server pre-check, run at most once per launch per server.
  static Future<void> _checkConnectionAndServer() {
    final baseUrl = ServerService().baseUrl;
    if (_verifiedBaseUrl == baseUrl) return Future.value();

    final running = _serverCheckInFlight;
    if (running != null && _serverCheckInFlightUrl == baseUrl) return running;

    final check = _runServerCheck(baseUrl).then((_) {
      _verifiedBaseUrl = baseUrl; // cache success only
    });
    _serverCheckInFlight = check;
    _serverCheckInFlightUrl = baseUrl;
    // Clear the shared future when done; errors are handled by callers.
    check.then<void>((_) {}, onError: (_) {}).whenComplete(() {
      if (identical(_serverCheckInFlight, check)) {
        _serverCheckInFlight = null;
        _serverCheckInFlightUrl = null;
      }
    });
    return check;
  }

  static Future<void> _runServerCheck(String baseUrl) async {
    // Step 1: Check internet connection first
    final hasInternet = await NetworkChecker.hasConnection();
    if (!hasInternet) {
      throw NetworkException(
        message:
            'No internet connection. Please check your network and try again',
      );
    }

    // Step 2: Check if server is up
    try {
      final response = await http
          .get(Uri.parse('${baseUrl}server-checking'))
          .timeout(_serverCheckTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return; // Server is up and running
        }
      }
      throw ServerException(
        message: 'Server is not responding correctly. Please try again later',
      );
    } on SocketException {
      throw ServerException(
        message: 'Unable to connect to server. Please try again later',
      );
    } on async.TimeoutException {
      throw ServerException(
        message: 'Server is not responding. Please try again later',
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        message: 'Unable to connect to server. Please try again later',
      );
    }
  }

  /// Sends a GET, or joins an identical one already in flight.
  static Future<http.Response> _sharedGet(
    String url,
    Map<String, String>? headers,
  ) {
    final key = '$url|${headers?['Authorization'] ?? ''}';
    final existing = _inFlightGets[key];
    if (existing != null) return existing;

    final request = http.get(Uri.parse(url), headers: headers).timeout(_timeout);
    _inFlightGets[key] = request;
    request.then<void>((_) {}, onError: (_) {}).whenComplete(() {
      if (identical(_inFlightGets[key], request)) _inFlightGets.remove(key);
    });
    return request;
  }

  /// Make GET request with error handling
  static Future<http.Response> get({
    required String url,
    Map<String, String>? headers,
    bool checkConnection = true,
  }) async {
    try {
      if (checkConnection) {
        await _checkConnectionAndServer();
      }

      final response = await _sharedGet(url, headers);

      ErrorHandler.handleHttpResponse(response);
      return response;
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } on SocketException {
      throw ServerException(
        message: 'Unable to connect to server. Please try again later',
      );
    } on async.TimeoutException {
      throw TimeoutException(message: _timeoutMessage);
    } on HttpException {
      throw ServerException(message: 'Network request failed');
    } on FormatException {
      throw DataParseException();
    } catch (e) {
      rethrow;
    }
  }

  /// GET that returns the response regardless of status code.
  ///
  /// Keeps the pre-check, sharing and timeout of [get], but does NOT call
  /// [ErrorHandler.handleHttpResponse]. Use when the caller needs the body
  /// of a 4xx, e.g. to show the API's own `message`.
  static Future<http.Response> getAllowingErrors({
    required String url,
    Map<String, String>? headers,
    bool checkConnection = true,
  }) async {
    try {
      if (checkConnection) {
        await _checkConnectionAndServer();
      }

      return await _sharedGet(url, headers);
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } on SocketException {
      throw ServerException(
        message: 'Unable to connect to server. Please try again later',
      );
    } on async.TimeoutException {
      throw TimeoutException(message: _timeoutMessage);
    } on HttpException {
      throw ServerException(message: 'Network request failed');
    } on FormatException {
      throw DataParseException();
    } catch (e) {
      rethrow;
    }
  }

  static const String _timeoutMessage =
      'The server is taking too long to respond. Please try again.';

  /// Make POST request with error handling
  static Future<http.Response> post({
    required String url,
    Map<String, String>? headers,
    dynamic body,
    bool checkConnection = true,
  }) async {
    try {
      // Check internet connection first
      if (checkConnection) {
        final hasInternet = await NetworkChecker.hasConnection();
        if (!hasInternet) {
          throw NetworkException();
        }
      }

      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body is Map || body is List ? json.encode(body) : body,
          )
          .timeout(_timeout);

      ErrorHandler.handleHttpResponse(response);
      return response;
    } on SocketException {
      throw NetworkException();
    } on async.TimeoutException {
      throw TimeoutException(message: _timeoutMessage);
    } on HttpException {
      throw NetworkException(message: 'Network request failed');
    } on FormatException {
      throw DataParseException();
    } catch (e) {
      rethrow;
    }
  }

  /// Make PUT request with error handling
  static Future<http.Response> put({
    required String url,
    Map<String, String>? headers,
    dynamic body,
    bool checkConnection = true,
  }) async {
    try {
      // Check internet connection first
      if (checkConnection) {
        final hasInternet = await NetworkChecker.hasConnection();
        if (!hasInternet) {
          throw NetworkException();
        }
      }

      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: body is Map || body is List ? json.encode(body) : body,
          )
          .timeout(_timeout);

      ErrorHandler.handleHttpResponse(response);
      return response;
    } on SocketException {
      throw NetworkException();
    } on async.TimeoutException {
      throw TimeoutException(message: _timeoutMessage);
    } on HttpException {
      throw NetworkException(message: 'Network request failed');
    } on FormatException {
      throw DataParseException();
    } catch (e) {
      rethrow;
    }
  }

  /// Make DELETE request with error handling
  static Future<http.Response> delete({
    required String url,
    Map<String, String>? headers,
    bool checkConnection = true,
  }) async {
    try {
      // Check internet connection first
      if (checkConnection) {
        final hasInternet = await NetworkChecker.hasConnection();
        if (!hasInternet) {
          throw NetworkException();
        }
      }

      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(_timeout);

      ErrorHandler.handleHttpResponse(response);
      return response;
    } on SocketException {
      throw NetworkException();
    } on async.TimeoutException {
      throw TimeoutException(message: _timeoutMessage);
    } on HttpException {
      throw NetworkException(message: 'Network request failed');
    } on FormatException {
      throw DataParseException();
    } catch (e) {
      rethrow;
    }
  }
}
