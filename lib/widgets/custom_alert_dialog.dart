import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/material.dart';

/// A simple customizable alert dialog widget that can be used throughout the app
class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? messageColor;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool barrierDismissible;
  final bool showIcon;
  final double? iconSize;
  final bool showIconBackground;
  final Color? iconBackgroundColor;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.titleColor,
    this.messageColor,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.barrierDismissible = false,
    this.showIcon = true,
    this.iconSize,
    this.showIconBackground = true,
    this.iconBackgroundColor,
  });

  /// Show a custom alert dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    Color? backgroundColor,
    Color? titleColor,
    Color? messageColor,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool barrierDismissible = false,
    bool showIcon = true,
    double? iconSize,
    bool showIconBackground = true,
    Color? iconBackgroundColor,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return CustomAlertDialog(
          title: title,
          message: message,
          icon: icon,
          iconColor: iconColor,
          backgroundColor: backgroundColor,
          titleColor: titleColor,
          messageColor: messageColor,
          primaryButtonText: primaryButtonText,
          secondaryButtonText: secondaryButtonText,
          onPrimaryPressed: onPrimaryPressed,
          onSecondaryPressed: onSecondaryPressed,
          barrierDismissible: barrierDismissible,
          showIcon: showIcon,
          iconSize: iconSize,
          showIconBackground: showIconBackground,
          iconBackgroundColor: iconBackgroundColor,
        );
      },
    );
  }

  /// Show an error dialog
  static Future<void> showError(
    BuildContext context, {
    String title = 'Error',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.error_outline,
      iconColor: primary,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }

  /// Show a success dialog
  static Future<void> showSuccess(
    BuildContext context, {
    String title = 'Success',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }

  /// Show a warning dialog
  static Future<void> showWarning(
    BuildContext context, {
    String title = 'Warning',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.warning_amber_outlined,
      iconColor: Colors.orange,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }

  /// Show an info dialog
  static Future<void> showInfo(
    BuildContext context, {
    String title = 'Information',
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context,
      title: title,
      message: message,
      icon: Icons.info_outline,
      iconColor: Colors.blue,
      primaryButtonText: buttonText,
      onPrimaryPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }

  /// Show a confirmation dialog with Yes/No buttons
  static Future<bool?> showConfirmation(
    BuildContext context, {
    String title = 'Confirm',
    required String message,
    IconData? icon,
    Color? iconColor,
    String yesButtonText = 'Yes',
    String noButtonText = 'No',
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          title: title,
          message: message,
          icon: icon ?? Icons.help_outline,
          iconColor: iconColor ?? Colors.blue,
          primaryButtonText: yesButtonText,
          secondaryButtonText: noButtonText,
          onPrimaryPressed: () => Navigator.of(context).pop(true),
          onSecondaryPressed: () => Navigator.of(context).pop(false),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(maxWidth: 350),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (showIcon && icon != null) ...[
                    _buildFancyIcon(),
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              // Message Section
              Padding(
                padding: const EdgeInsets.only(left: 32, right: 32),
                child: Text(
                  message,
                  style: TextStyle(
                    color: messageColor ?? Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              // Action Buttons
              _buildActionButtons(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFancyIcon() {
    final effectiveIconColor = iconColor ?? Colors.blue;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Icon(icon, color: effectiveIconColor, size: iconSize ?? 32),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasSecondaryButton = secondaryButtonText != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Secondary button (if provided)
          if (hasSecondaryButton) ...[
            Expanded(child: _buildSecondaryButton(context)),
            const SizedBox(width: 8),
          ],
          // Primary button
          Expanded(child: _buildPrimaryButton(context)),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    return ElevatedButton(
      onPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
      style: ElevatedButton.styleFrom(
        backgroundColor: iconColor ?? Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        primaryButtonText ?? 'OK',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context) {
    return OutlinedButton(
      onPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        foregroundColor: iconColor ?? Theme.of(context).primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(
          color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.3),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        secondaryButtonText!,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
