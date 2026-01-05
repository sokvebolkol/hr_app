import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'exceptions.dart';

/// Centralized error handler for the application
class ErrorHandler {
  /// Handle HTTP response and throw appropriate exceptions
  static void handleHttpResponse(http.Response response) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      return; // Success
    }

    // Handle different error status codes
    switch (statusCode) {
      case 400:
        throw ClientException(
          message: 'Bad request. Please check your input.',
          statusCode: statusCode,
        );
      case 401:
        throw UnauthorizedException(
          message: 'Session expired. Please login again.',
        );
      case 403:
        throw UnauthorizedException(
          message: 'You do not have permission to access this resource.',
        );
      case 404:
        throw NotFoundException(
          message: 'The requested resource was not found.',
        );
      case 408:
        throw TimeoutException(message: 'Request timeout. Please try again.');
      case 422:
        throw ValidationException(
          message: 'Validation failed. Please check your input.',
        );
      case 429:
        throw ClientException(
          message: 'Too many requests. Please try again later.',
          statusCode: statusCode,
        );
      case 500:
      case 501:
      case 502:
      case 503:
      case 504:
        throw ServerException(
          message: 'Server error occurred. Please try again later.',
          statusCode: statusCode,
        );
      default:
        throw AppException(
          message: 'An unexpected error occurred (Code: $statusCode)',
          prefix: 'HTTP Error',
        );
    }
  }

  /// Convert exceptions to user-friendly error messages
  static String getErrorMessage(dynamic error) {
    // Handle known app exceptions first (most specific)
    if (error is NetworkException) {
      return 'No internet connection. Please check your network and try again';
    }

    if (error is AppException) {
      return error.message;
    }

    // Handle built-in exception types
    if (error is SocketException) {
      // Check if it's a connection refused (server down) vs no internet
      final errorString = error.toString();
      if (errorString.contains('Connection refused') ||
          errorString.contains('Connection reset') ||
          errorString.contains('Connection closed')) {
        return 'Unable to connect to server. Please try again later';
      }
      // Failed host lookup means no internet or DNS issue
      if (errorString.contains('Failed host lookup')) {
        return 'No internet connection. Please check your network and try again';
      }
      // Default for other socket exceptions
      return 'Unable to connect to server. Please check your connection';
    }

    if (error is HttpException) {
      return 'Network error occurred. Please try again';
    }

    if (error is FormatException) {
      return 'Invalid data received. Please try again';
    }

    // Handle specific error messages from repositories
    if (error is Exception) {
      final errorString = error.toString();

      // Check for specific error patterns
      if (errorString.contains('NO_INTERNET')) {
        return 'No internet connection. Please check your network and try again';
      }

      if (errorString.contains('Connection refused') ||
          errorString.contains('Connection reset') ||
          errorString.contains('Connection closed')) {
        return 'Unable to connect to server. Please try again later';
      }

      if (errorString.contains('Failed host lookup')) {
        return 'No internet connection. Please check your network and try again';
      }

      if (errorString.contains('SocketException')) {
        return 'Unable to connect to server. Please check your connection';
      }

      if (errorString.contains('TimeoutException') ||
          errorString.contains('timed out')) {
        return 'Request timeout. Please try again';
      }

      if (errorString.contains('HandshakeException') ||
          errorString.contains('CERTIFICATE_VERIFY_FAILED')) {
        return 'Secure connection failed. Please try again';
      }

      if (errorString.contains('FormatException') ||
          errorString.contains('Unexpected character')) {
        return 'Invalid data received from server. Please try again';
      }

      if (errorString.contains('Session expired') ||
          errorString.contains('Token not found') ||
          errorString.contains('User ID not found')) {
        return 'Session expired. Please login again';
      }

      // Extract message from Exception
      final message = errorString.replaceFirst('Exception: ', '');
      if (message.isNotEmpty && message != errorString) {
        return message;
      }
    }

    // Default error message
    return 'An unexpected error occurred. Please try again';
  }

  /// Log error for debugging (can be extended to send to crash reporting service)
  static void logError(dynamic error, StackTrace? stackTrace) {}

  /// Show error as a modal dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    dynamic error,
    String? title,
    String? message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    final errorMessage = message ?? getErrorMessage(error);
    final errorTitle = title ?? _getErrorTitle(error, errorMessage);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _getErrorIcon(error, errorMessage),
                  color: _getErrorColor(error, errorMessage),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              if (onDismiss != null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss.call();
                  },
                  child: const Text('Cancel'),
                ),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRetry.call();
                  },
                  child: const Text('Retry'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDismiss?.call();
                  },
                  child: const Text('OK'),
                ),
            ],
          ),
    );
  }

  /// Get appropriate title based on error type
  static String _getErrorTitle(dynamic error, String message) {
    if (error is NetworkException) return 'Connection Error';
    if (error is ServerException) return 'Server Error';
    if (error is UnauthorizedException) return 'Authentication Required';
    if (error is TimeoutException) return 'Timeout';
    if (error is DataParseException) return 'Data Error';
    if (error is ValidationException) return 'Validation Error';
    if (error is NotFoundException) return 'Not Found';

    // Detect from message if error object not available
    if (message.contains('No internet connection')) {
      return 'No Internet';
    }
    if (message.contains('Unable to connect to server')) {
      return 'Server Unavailable';
    }
    if (message.contains('network')) {
      return 'Connection Error';
    }
    if (message.contains('Server error')) return 'Server Error';
    if (message.contains('Session expired') || message.contains('login')) {
      return 'Authentication Required';
    }
    if (message.contains('timeout')) return 'Timeout';

    return 'Error';
  }

  /// Get appropriate icon based on error type
  static IconData _getErrorIcon(dynamic error, String message) {
    if (error is NetworkException) return Icons.wifi_off;
    if (error is ServerException) return Icons.cloud_off;
    if (error is UnauthorizedException) return Icons.lock_outline;
    if (error is TimeoutException) return Icons.timer_off;
    if (error is DataParseException) return Icons.broken_image_outlined;
    if (error is ValidationException) return Icons.warning_amber;
    if (error is NotFoundException) return Icons.search_off;

    // Detect from message if error object not available
    if (message.contains('No internet connection')) {
      return Icons.wifi_off;
    }
    if (message.contains('Unable to connect to server')) {
      return Icons.cloud_off;
    }
    if (message.contains('network')) {
      return Icons.wifi_off;
    }
    if (message.contains('Server error')) return Icons.cloud_off;
    if (message.contains('Session expired') || message.contains('login')) {
      return Icons.lock_outline;
    }
    if (message.contains('timeout')) return Icons.timer_off;
    if (message.contains('Invalid data')) return Icons.broken_image_outlined;
    if (message.contains('Validation')) return Icons.warning_amber;
    if (message.contains('not found')) return Icons.search_off;

    return Icons.error_outline;
  }

  /// Get appropriate color based on error type
  static Color _getErrorColor(dynamic error, String message) {
    if (error is NetworkException) return Colors.orange;
    if (error is UnauthorizedException) return Colors.red;
    if (error is ValidationException) return Colors.amber;

    // Detect from message if error object not available
    if (message.contains('No internet connection')) {
      return Colors.orange;
    }
    if (message.contains('Unable to connect to server')) {
      return Colors.red;
    }
    if (message.contains('network')) {
      return Colors.orange;
    }
    if (message.contains('Session expired') || message.contains('login')) {
      return Colors.red;
    }
    if (message.contains('Validation')) return Colors.amber;

    return Colors.red;
  }
}
