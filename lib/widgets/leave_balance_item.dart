import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/material.dart';

class LeaveBalanceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String label;
  final dynamic remainingDays;
  final dynamic totalDays;
  final Color color;
  final Color barColor;
  final bool isNoUsedItem;

  const LeaveBalanceItem({
    Key? key,
    required this.icon,
    required this.title,
    this.label = "forwarded balance",
    required this.remainingDays,
    required this.totalDays,
    required this.color,
    this.barColor = secondary,
    this.isNoUsedItem = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = (totalDays == 0.0) ? 0.0 : (remainingDays / totalDays);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 8),
                isNoUsedItem
                    ? Text(
                      '$remainingDays day(s) remaining of $totalDays',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    )
                    : Text(
                      '$remainingDays $label',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DividerItem extends StatelessWidget {
  const DividerItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.grey[300], thickness: 1, height: 20);
  }
}
