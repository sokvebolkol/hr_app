import 'package:flutter/material.dart';

import '../constants/constant.dart';

enum DialogType { success, error, warning, info, question }

class FancyDialog {
  static Future<bool?> show({
    required BuildContext context,
    required DialogType dialogType,
    required String title,
    required String description,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool dismissible = true,
    bool showCancelButton = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: dismissible,
      builder: (BuildContext context) {
        return _FancyDialogWidget(
          dialogType: dialogType,
          title: title,
          description: description,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: onConfirm,
          onCancel: onCancel,
          showCancelButton: showCancelButton,
        );
      },
    );
  }
}

class _FancyDialogWidget extends StatefulWidget {
  final DialogType dialogType;
  final String title;
  final String description;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showCancelButton;

  const _FancyDialogWidget({
    required this.dialogType,
    required this.title,
    required this.description,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.showCancelButton = true,
  });

  @override
  State<_FancyDialogWidget> createState() => _FancyDialogWidgetState();
}

class _FancyDialogWidgetState extends State<_FancyDialogWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getDialogColor() {
    switch (widget.dialogType) {
      case DialogType.success:
        return Colors.green;
      case DialogType.error:
        return Colors.red;
      case DialogType.warning:
        return Colors.orange;
      case DialogType.info:
        return secondary;
      case DialogType.question:
        return primary;
    }
  }

  IconData _getDialogIcon() {
    switch (widget.dialogType) {
      case DialogType.success:
        return Icons.check_circle;
      case DialogType.error:
        return Icons.error;
      case DialogType.warning:
        return Icons.warning;
      case DialogType.info:
        return Icons.info;
      case DialogType.question:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getDialogColor();
    final icon = _getDialogIcon();

    return FadeTransition(
      opacity: _opacityAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.8), color],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Animated icon
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(icon, size: 48, color: color),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.showCancelButton) ...[
                              Expanded(
                                child: _buildButton(
                                  text: widget.cancelText ?? 'Cancel',
                                  color: Colors.grey[400]!,
                                  textColor: Colors.grey[700]!,
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                    widget.onCancel?.call();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: _buildButton(
                                text: widget.confirmText ?? 'OK',
                                color: color,
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  widget.onConfirm?.call();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
