import 'package:flutter/material.dart';
import '../utils/file_helper.dart';

class CompactStatusCard extends StatelessWidget {
  final String status;
  final String statusText;
  final String id;
  final String duration;
  final String durationType;
  final bool hasDocument;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? iconSize;
  final TextStyle? titleStyle;
  final TextStyle? idStyle;
  final TextStyle? durationStyle;
  final TextStyle? typeStyle;
  final TextStyle? documentStyle;
  final String? customTitle;
  final Widget? customRightWidget;

  const CompactStatusCard({
    super.key,
    required this.status,
    required this.statusText,
    required this.id,
    required this.duration,
    required this.durationType,
    this.hasDocument = false,
    this.padding,
    this.borderRadius,
    this.iconSize,
    this.titleStyle,
    this.idStyle,
    this.durationStyle,
    this.typeStyle,
    this.documentStyle,
    this.customTitle,
    this.customRightWidget,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = FileHelper.getStatusColor(status);
    final statusIcon = FileHelper.getStatusIcon(status);

    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [statusColor, statusColor.withOpacity(0.8)],
        ),
        boxShadow: [
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
          // Status Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, size: iconSize ?? 32, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customTitle ?? statusText,
                  style:
                      titleStyle ??
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $id',
                  style:
                      idStyle ??
                      const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),

          // Right Side Info
          customRightWidget ?? _buildDefaultRightWidget(),
        ],
      ),
    );
  }

  Widget _buildDefaultRightWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          duration,
          style:
              durationStyle ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        Text(
          durationType,
          style:
              typeStyle ?? const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        if (hasDocument) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_file, size: 12, color: Colors.white70),
              const SizedBox(width: 2),
              Text(
                'Document',
                style:
                    documentStyle ??
                    const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
