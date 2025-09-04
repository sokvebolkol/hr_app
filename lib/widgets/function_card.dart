import 'package:flutter/material.dart';
import '../constants/constant.dart';

class FunctionIconCardWidget extends StatelessWidget {
  final IconData iconData;
  final String label;
  final Color iconColor;
  final double? iconSize;
  final double? textSize;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  const FunctionIconCardWidget({
    super.key,
    required this.iconData,
    this.textSize = 12,
    this.iconSize = 40,
    required this.label,
    this.iconColor = primary,
    this.backgroundColor = Colors.white,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(child: Icon(iconData, color: iconColor, size: iconSize)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: textSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
