import 'package:flutter/material.dart';

class CompactStatusCard extends StatelessWidget {
  final String status;
  final String statusText;
  final String id;
  final String duration;
  final String dayType;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? iconSize;
  final List<BoxShadow>? boxShadow;
  final Widget? additionalInfo;
  final String? idLabel;

  const CompactStatusCard({
    super.key,
    required this.status,
    required this.statusText,
    required this.id,
    required this.duration,
    required this.dayType,
    required this.getStatusColor,
    required this.getStatusIcon,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.boxShadow,
    this.additionalInfo,
    this.idLabel = 'ID',
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(status);

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor, statusColor.withOpacity(0.8)],
        ),
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: statusColor.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              getStatusIcon(status),
              size: iconSize ?? 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$idLabel: $id',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Quick info on the right
          additionalInfo ?? _buildDefaultRightInfo(),
        ],
      ),
    );
  }

  Widget _buildDefaultRightInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          duration,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          dayType,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
