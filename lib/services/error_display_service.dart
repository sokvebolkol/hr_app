import 'package:flutter/material.dart';
import '../utils/error_handler.dart';
import '../utils/exceptions.dart';
import '../widgets/fancy_dialog.dart';

/// Service to display errors to users using FancyDialog
class ErrorDisplayService {
  /// Show error using FancyDialog with appropriate type and message
  static Future<void> showError(
    BuildContext context, {
    required dynamic error,
    String? customTitle,
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    if (!context.mounted) return;

    final errorMessage = customMessage ?? ErrorHandler.getErrorMessage(error);
    final dialogType = _getDialogType(error, errorMessage);
    final title = customTitle ?? _getErrorTitle(error, errorMessage);

    await FancyDialog.show(
      context: context,
      dialogType: dialogType,
      title: title,
      description: errorMessage,
      confirmText: onRetry != null ? 'Retry' : 'OK',
      cancelText: onRetry != null ? 'Cancel' : null,
      showCancelButton: onRetry != null,
      dismissible: false,
      onConfirm: () {
        if (onRetry != null) {
          onRetry();
        } else {
          onDismiss?.call();
        }
      },
      onCancel: onDismiss,
    );
  }

  /// Show network error with retry option
  static Future<void> showNetworkError(
    BuildContext context, {
    required VoidCallback onRetry,
    VoidCallback? onDismiss,
  }) async {
    if (!context.mounted) return;

    await FancyDialog.show(
      context: context,
      dialogType: DialogType.warning,
      title: 'No Internet Connection',
      description:
          'Please check your network connection and try again. Make sure WiFi or mobile data is enabled.',
      confirmText: 'Retry',
      cancelText: 'Cancel',
      showCancelButton: true,
      dismissible: false,
      onConfirm: onRetry,
      onCancel: onDismiss,
    );
  }

  /// Show server error
  static Future<void> showServerError(
    BuildContext context, {
    String? message,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    if (!context.mounted) return;

    await FancyDialog.show(
      context: context,
      dialogType: DialogType.error,
      title: 'Server Error',
      description:
          message ??
          'Our server is currently experiencing issues. Please try again later or contact support if the problem persists.',
      confirmText: onRetry != null ? 'Retry' : 'OK',
      cancelText: onRetry != null ? 'Cancel' : null,
      showCancelButton: onRetry != null,
      dismissible: false,
      onConfirm: () {
        if (onRetry != null) {
          onRetry();
        } else {
          onDismiss?.call();
        }
      },
      onCancel: onDismiss,
    );
  }

  /// Show session expired error (requires login)
  static Future<void> showSessionExpiredError(
    BuildContext context, {
    required VoidCallback onLogin,
  }) async {
    if (!context.mounted) return;

    await FancyDialog.show(
      context: context,
      dialogType: DialogType.warning,
      title: 'Session Expired',
      description:
          'Your session has expired for security reasons. Please login again to continue.',
      confirmText: 'Login',
      showCancelButton: false,
      dismissible: false,
      onConfirm: onLogin,
    );
  }

  /// Show generic success message
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
  }) async {
    if (!context.mounted) return;

    await FancyDialog.show(
      context: context,
      dialogType: DialogType.success,
      title: title,
      description: message,
      confirmText: 'OK',
      showCancelButton: false,
      onConfirm: onDismiss ?? () {},
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    DialogType type = DialogType.question,
  }) async {
    if (!context.mounted) return false;

    final result = await FancyDialog.show(
      context: context,
      dialogType: type,
      title: title,
      description: message,
      confirmText: confirmText,
      cancelText: cancelText,
      showCancelButton: true,
    );

    return result ?? false;
  }

  /// Get appropriate dialog type based on error
  static DialogType _getDialogType(dynamic error, String errorMessage) {
    if (error is NetworkException ||
        errorMessage.toLowerCase().contains('internet') ||
        errorMessage.toLowerCase().contains('network')) {
      return DialogType.warning;
    }

    if (error is ServerException ||
        errorMessage.toLowerCase().contains('server')) {
      return DialogType.error;
    }

    if (error is UnauthorizedException ||
        errorMessage.toLowerCase().contains('session') ||
        errorMessage.toLowerCase().contains('login')) {
      return DialogType.warning;
    }

    if (error is ValidationException ||
        errorMessage.toLowerCase().contains('validation')) {
      return DialogType.info;
    }

    return DialogType.error;
  }

  /// Get appropriate error title
  static String _getErrorTitle(dynamic error, String errorMessage) {
    if (error is NetworkException ||
        errorMessage.toLowerCase().contains('internet') ||
        errorMessage.toLowerCase().contains('network')) {
      return 'Connection Error';
    }

    if (error is ServerException ||
        errorMessage.toLowerCase().contains('server')) {
      return 'Server Error';
    }

    if (error is UnauthorizedException ||
        errorMessage.toLowerCase().contains('session')) {
      return 'Session Expired';
    }

    if (error is ValidationException) {
      return 'Validation Error';
    }

    if (error is TimeoutException ||
        errorMessage.toLowerCase().contains('timeout')) {
      return 'Request Timeout';
    }

    if (error is NotFoundException) {
      return 'Not Found';
    }

    return 'Error';
  }
}
