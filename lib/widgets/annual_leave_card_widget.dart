import 'package:flutter/material.dart';
import '../constants/constant.dart';
import 'custom_progress_bar.dart';

class AnnualLeaveBalanceWidget extends StatelessWidget {
  final String usedLeave;
  final String title;
  final String dayAvailableText;
  final String viewDetailsText;
  final String availableLeave;
  final String usedLeaveText;
  final String availableLeaveText;
  final VoidCallback? onViewDetails;

  const AnnualLeaveBalanceWidget({
    super.key,
    required this.usedLeave,
    required this.title,
    required this.dayAvailableText,
    required this.viewDetailsText,
    required this.availableLeave,
    required this.usedLeaveText,
    required this.availableLeaveText,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    double used = double.tryParse(usedLeave) ?? 0;
    double available = double.tryParse(availableLeave) ?? 0;
    double total = used + available;
    double progress = total > 0 ? used / total : 0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onViewDetails,
                child: Text(
                  viewDetailsText,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            availableLeave,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            // textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      dayAvailableText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    EllipticalProgressBar(
                      progress: progress,
                      backgroundColor: Colors.grey.shade200,
                      progressColor: logoPink,
                      height: 10.0,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$usedLeaveText: $usedLeave',
                              style: const TextStyle(
                                fontSize: 10,
                                color: logoPink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '$availableLeaveText: $total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
