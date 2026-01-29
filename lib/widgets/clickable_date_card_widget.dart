import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClickableDateCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  const ClickableDateCard({
    super.key,
    required this.label,
    required this.date,
    required this.icon,
    required this.color,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM dd, yyyy');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
            width: isActive ? 1 : 0.5,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                if (isActive) Icon(Icons.check_circle, size: 14, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(date),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
