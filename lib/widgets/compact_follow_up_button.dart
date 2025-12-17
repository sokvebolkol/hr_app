import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/material.dart';

class CompactFollowUpButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final IconData icon;
  final List<Color>? gradientColors;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? iconSize;
  final double? fontSize;
  final double? spacing;
  final Color? textColor;

  const CompactFollowUpButton({
    super.key,
    required this.onTap,
    this.text = 'Follow Up',
    this.icon = Icons.message,
    this.gradientColors,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.fontSize,
    this.spacing,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors ?? [primary, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(borderRadius ?? 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize ?? 10, color: textColor ?? Colors.white),
            SizedBox(width: spacing ?? 3),
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize ?? 10,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
