/// Custom exceptions for better error handling
class AppException implements Exception {
  final String message;
  final String? prefix;
  final dynamic originalError;

  AppException({required this.message, this.prefix, this.originalError});

  @override
  String toString() {
    return '${prefix ?? "Error"}: $message';
  }
}

/// Exception for network connectivity issues
class NetworkException extends AppException {
  NetworkException({String? message})
    : super(
        message:
            message ?? 'No internet connection. Please check your network.',
        prefix: 'Network Error',
      );
}

/// Exception for server errors (5xx)
class ServerException extends AppException {
  final int? statusCode;

  ServerException({String? message, this.statusCode})
    : super(
        message: message ?? 'Server error occurred. Please try again later.',
        prefix: 'Server Error',
      );
}

/// Exception for client errors (4xx)
class ClientException extends AppException {
  final int? statusCode;

  ClientException({required super.message, this.statusCode})
    : super(prefix: 'Request Error');
}

/// Exception for authentication/authorization errors (401, 403)
class UnauthorizedException extends AppException {
  UnauthorizedException({String? message})
    : super(
        message: message ?? 'Session expired. Please login again.',
        prefix: 'Authentication Error',
      );
}

/// Exception for timeout errors
class TimeoutException extends AppException {
  TimeoutException({String? message})
    : super(
        message: message ?? 'Request timeout. Please try again.',
        prefix: 'Timeout Error',
      );
}

/// Exception for data parsing errors
class DataParseException extends AppException {
  DataParseException({String? message})
    : super(
        message: message ?? 'Failed to process data. Please try again.',
        prefix: 'Data Error',
      );
}

/// Exception for validation errors
class ValidationException extends AppException {
  ValidationException({required super.message})
    : super(prefix: 'Validation Error');
}

/// Exception for not found errors (404)
class NotFoundException extends AppException {
  NotFoundException({String? message})
    : super(
        message: message ?? 'Requested resource not found.',
        prefix: 'Not Found',
      );
}
