import 'package:flutter/material.dart';

class ActionButtonData {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;

  const ActionButtonData({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
  });
}

enum ButtonLayout { column, row }

class ActionButtonsCard extends StatelessWidget {
  final List<ActionButtonData> buttons;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double? buttonHeight;
  final double? spacing;
  final EdgeInsetsGeometry? buttonPadding;
  final double? buttonBorderRadius;
  final ButtonLayout layout;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;

  const ActionButtonsCard({
    super.key,
    required this.buttons,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.buttonHeight,
    this.spacing,
    this.buttonPadding,
    this.buttonBorderRadius,
    this.layout = ButtonLayout.column,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child:
          layout == ButtonLayout.column
              ? _buildColumnLayout()
              : _buildRowLayout(),
    );
  }

  Widget _buildColumnLayout() {
    return Column(
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.stretch,
      children:
          buttons.asMap().entries.map((entry) {
            final index = entry.key;
            final button = entry.value;
            final isLast = index == buttons.length - 1;

            return Column(
              children: [
                _buildActionButton(button),
                if (!isLast) SizedBox(height: spacing ?? 12),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildRowLayout() {
    return Row(
      mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
      children:
          buttons.asMap().entries.map((entry) {
            final index = entry.key;
            final button = entry.value;
            final isLast = index == buttons.length - 1;

            return Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildActionButton(button)),
                  if (!isLast) SizedBox(width: spacing ?? 12),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildActionButton(ActionButtonData button) {
    return SizedBox(
      width: layout == ButtonLayout.row ? null : double.infinity,
      height: buttonHeight,
      child: ElevatedButton.icon(
        onPressed: button.isLoading ? null : button.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: button.backgroundColor,
          foregroundColor: button.foregroundColor ?? Colors.white,
          padding: buttonPadding ?? const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius ?? 12),
          ),
          elevation: 2,
        ),
        icon:
            button.isLoading
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      button.foregroundColor ?? Colors.white,
                    ),
                  ),
                )
                : Icon(button.icon, size: 18),
        label: Text(
          button.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: button.foregroundColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
