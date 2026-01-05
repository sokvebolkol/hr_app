import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/exceptions.dart';
import '../utils/error_handler.dart';
import '../utils/network_checker.dart';
import 'global_service.dart';

/// HTTP service wrapper with built-in error handling
class HttpService {
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _serverCheckTimeout = Duration(seconds: 5);

  /// Check both internet connection and server status
  static Future<void> _checkConnectionAndServer() async {
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
      final serverService = ServerService();
      final response = await http
          .get(Uri.parse('${serverService.baseUrl}server-checking'))
          .timeout(_serverCheckTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return; // Server is up and running
        }
      }
      // Server responded but not with expected response
      throw ServerException(
        message: 'Server is not responding correctly. Please try again later',
      );
    } on SocketException {
      throw ServerException(
        message: 'Unable to connect to server. Please try again later',
      );
    } on TimeoutException {
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

  /// Make GET request with error handling
  static Future<http.Response> get({
    required String url,
    Map<String, String>? headers,
    bool checkConnection = true,
  }) async {
    try {
      // Check internet and server status first
      if (checkConnection) {
        await _checkConnectionAndServer();
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_timeout);

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
    } on TimeoutException {
      throw TimeoutException();
    } on HttpException {
      throw ServerException(message: 'Network request failed');
    } on FormatException {
      throw DataParseException();
    } catch (e) {
      rethrow;
    }
  }

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
    } on TimeoutException {
      throw TimeoutException();
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
    } on TimeoutException {
      throw TimeoutException();
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
    } on TimeoutException {
      throw TimeoutException();
    } on HttpException {
      throw NetworkException(message: 'Network request failed');
    } on FormatException {
      throw DataParseException();
    } catch (e) {
      rethrow;
    }
  }
}
