import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/network_checker.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';

/// Example base repository showing best practices for error handling
///
/// This demonstrates how to:
/// 1. Check internet connection before API calls
/// 2. Handle different types of errors
/// 3. Throw appropriate exceptions
class BaseRepository {
  /// Make an API call with proper error handling
  ///
  /// Usage:
  /// ```dart
  /// final response = await makeApiCall(
  ///   () => http.get(Uri.parse('$baseUrl/endpoint'), headers: headers),
  ///   errorContext: 'fetching user data',
  /// );
  /// ```
  Future<http.Response> makeApiCall(
    Future<http.Response> Function() apiCall, {
    String errorContext = 'making request',
    bool checkConnection = true,
  }) async {
    try {
      // 1. Check internet connection first
      if (checkConnection) {
        await NetworkChecker.checkConnectivity();
      }

      // 2. Make the API call
      final response = await apiCall();

      // 3. Handle HTTP errors
      ErrorHandler.handleHttpResponse(response);

      return response;
    } on NetworkException {
      // Already has good message
      rethrow;
    } on SocketException catch (e) {
      final errorString = e.toString();
      if (errorString.contains('Connection refused') ||
          errorString.contains('Connection reset')) {
        throw ServerException(
          message: 'Unable to connect to server. Please try again later.',
        );
      }
      if (errorString.contains('Failed host lookup')) {
        throw NetworkException(
          message: 'No internet connection. Please check your network.',
        );
      }
      throw NetworkException(
        message: 'Unable to connect to server. Please check your connection.',
      );
    } on HttpException {
      throw NetworkException(
        message: 'Network error occurred. Please try again.',
      );
    } on FormatException {
      throw DataParseException(
        message: 'Invalid data received from server. Please try again.',
      );
    } on AppException {
      // Already handled
      rethrow;
    } catch (e) {
      // Unknown error
      throw AppException(
        message: 'An unexpected error occurred while $errorContext',
        originalError: e,
      );
    }
  }

  /// Make an API call with timeout
  Future<http.Response> makeApiCallWithTimeout(
    Future<http.Response> Function() apiCall, {
    Duration timeout = const Duration(seconds: 30),
    String errorContext = 'making request',
    bool checkConnection = true,
  }) async {
    try {
      return await makeApiCall(
        apiCall,
        errorContext: errorContext,
        checkConnection: checkConnection,
      ).timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(
            message:
                'Request timeout. Please check your connection and try again.',
          );
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Example usage in a real repository
class ExampleLeaveRepository extends BaseRepository {
  final String baseUrl = 'https://api.example.com';

  Future<Map<String, dynamic>> getLeaveData(String token) async {
    // This will:
    // 1. Check internet connection
    // 2. Make API call
    // 3. Handle all errors properly
    // 4. Throw appropriate exceptions that can be caught in UI
    final response = await makeApiCallWithTimeout(
      () => http.get(
        Uri.parse('$baseUrl/leave-data'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
      timeout: const Duration(seconds: 30),
      errorContext: 'fetching leave data',
    );

    // Parse response
    try {
      final data = jsonDecode(response.body);
      return data as Map<String, dynamic>;
    } catch (e) {
      throw DataParseException(
        message: 'Failed to process leave data. Please try again.',
      );
    }
  }
}
