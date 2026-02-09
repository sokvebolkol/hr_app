import 'package:flutter/material.dart';

class VerticalApproverFlow extends StatelessWidget {
  final List<ApproverData> approvers;
  final Color? lineColor;
  final Color? dotColor;

  const VerticalApproverFlow({
    super.key,
    required this.approvers,
    this.lineColor,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    if (approvers.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final finalLineColor = lineColor ?? primary.withValues(alpha: 0.4);
    final finalDotColor = dotColor ?? primary;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(approvers.length, (index) {
          final approver = approvers[index];
          final isLast = index == approvers.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// LEFT SIDE (Dot + Line)
                Column(
                  children: [
                    _Dot(color: finalDotColor),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: finalLineColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      approver.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class ApproverData {
  final String name;
  final int level;

  const ApproverData({required this.name, required this.level});
}
