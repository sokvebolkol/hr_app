import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveRequestWidget extends StatelessWidget {
  final String leaveType;
  final String reason;
  final String status;
  final String fromDate;
  final String toDate;
  final String? requesterName;
  final String? totalDays;
  final List<String>? approvers;
  final int approvedSteps; // Number of steps approved

  const LeaveRequestWidget({
    super.key,
    required this.leaveType,
    required this.reason,
    required this.status,
    required this.fromDate,
    required this.toDate,
    this.requesterName,
    this.totalDays,
    this.approvers,
    this.approvedSteps = 0,
  });

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MMM-yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final approverList =
        approvers ?? ['First Approver', 'Second Approver', 'HR(Default)'];
    final name = requesterName ?? 'Employee';
    final days = totalDays ?? '';
    final statusColor =
        status == "Approved"
            ? Colors.green
            : status == "Rejected"
            ? Colors.red
            : Colors.orangeAccent;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage('assets/images/my-profile.png'),
                  backgroundColor: Colors.blueAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  days.isNotEmpty ? 'Total $days day(s)' : '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            const Divider(color: Colors.grey, thickness: 0.3),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Icon(Icons.calendar_month, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${_formatDate(fromDate)} → ${_formatDate(toDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Reason: $reason',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'STATUS: $status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    ...List.generate(
                      approverList.length,
                      (i) => Row(
                        children: [
                          _buildCircle(i < approvedSteps),
                          if (i < approverList.length - 1)
                            _buildConnectingLine(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      approverList
                          .map(
                            (a) => Text(
                              a,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    approverList.indexOf(a) < approvedSteps
                                        ? Colors.black
                                        : Colors.grey,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Type: $leaveType',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(bool isActive) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.green : Colors.grey[400],
      ),
    );
  }

  Widget _buildConnectingLine() {
    return Container(width: 132, height: 2, color: Colors.grey[400]);
  }
}
