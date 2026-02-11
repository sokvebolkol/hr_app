import 'package:flutter/material.dart';
import '../constants/constant.dart';
import 'custom_progress_bar.dart';

class AnnualLeaveBalanceWidget extends StatelessWidget {
  final String usedLeave;
  final String title;
  final String viewDetailsText;
  final String availableLeave;
  final String usedLeaveText;
  final String availableLeaveText;
  final VoidCallback? onViewDetails;

  const AnnualLeaveBalanceWidget({
    super.key,
    required this.usedLeave,
    required this.title,
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
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: onViewDetails,
                child: Text(
                  viewDetailsText,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: logoPink,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '$usedLeaveText: $usedLeave days',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    '$availableLeaveText: $availableLeave days',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            availableLeave,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    EllipticalProgressBar(
                      progress: progress,
                      backgroundColor: Colors.grey.shade200,
                      progressColor: logoPink,
                      height: 25.0,
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
