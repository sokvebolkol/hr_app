import 'package:flutter/material.dart';

class EllipticalProgressBar extends StatelessWidget {
  final double progress; // Value between 0.0 and 1.0
  final Color backgroundColor;
  final Color progressColor;
  final double height;

  const EllipticalProgressBar({
    Key? key,
    required this.progress,
    this.backgroundColor = Colors.teal,
    this.progressColor = Colors.pink,
    this.height = 25.0, // Default height
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EllipseProgressPainter(
        progress,
        backgroundColor,
        progressColor,
        height,
      ),
      child: SizedBox(width: double.infinity, height: height),
    );
  }
}

class _EllipseProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double height;

  _EllipseProgressPainter(
    this.progress,
    this.backgroundColor,
    this.progressColor,
    this.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paintBackground =
        Paint()
          ..color = backgroundColor
          ..style = PaintingStyle.fill;

    // Draw the background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, height),
        Radius.circular(
          height / 2,
        ), // Half height makes it perfectly elliptical
      ),
      paintBackground,
    );

    final paintProgress =
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.fill;

    // Draw the progress
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width * progress, height),
        Radius.circular(
          height / 2,
        ), // This ensures the active part also has rounded ends
      ),
      paintProgress,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate != this;
}
