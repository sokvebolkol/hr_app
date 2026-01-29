import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:chokchey_hr_app/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class CalendarCardWidget extends StatelessWidget {
  static const List<Color> _colorOptions = [primary, secondary, logoPink];

  final int day;
  final int month;
  final double width;
  final double height;
  final double borderRadius;

  const CalendarCardWidget({
    super.key,
    required this.day,
    required this.month,
    this.width = 50,
    this.height = 65,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random(day + month); // deterministic
    final Color headerColor =
        _colorOptions[random.nextInt(_colorOptions.length)];
    final Color lightBg = headerColor.withOpacity(0.12);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [headerColor, headerColor.withOpacity(0.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
              ),
            ),
            child: Text(
              FileHelper().getMonthShortName(month).toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.4,
              ),
            ),
          ),
          /// subtle paper tear divider
          Container(height: 1, color: Colors.white.withOpacity(0.6)),
          /// 📆 Day Section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(borderRadius),
                ),
              ),
              child: Center(
                child: Text(
                  day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
