import 'package:flutter/material.dart';

class LeaveCard extends StatelessWidget {
  final String leaveTypeId;
  final String startDate;
  final String endDate;
  final String createdDate;
  final String employeeName;
  final String totalDays;
  final Color iconColor;

  const LeaveCard({
    Key? key,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.createdDate,
    required this.employeeName,
    required this.totalDays,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String leaveType = "Hello";

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              leaveType,
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 30, color: iconColor),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          startDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const Icon(Icons.arrow_right_alt, color: Colors.grey),
                        Text(
                          endDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employeeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Requested Date: $createdDate",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Total: $totalDays day(s)',
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
