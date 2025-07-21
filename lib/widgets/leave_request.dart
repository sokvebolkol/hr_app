import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/file_helper.dart';

class LeaveRequestWidget extends StatefulWidget {
  final String reason;
  final String status;
  final String fromDate;
  final String toDate;
  final String? requesterName;
  final String? totalDays;
  final List<Map<String, dynamic>>? prioList;

  const LeaveRequestWidget({
    super.key,
    required this.reason,
    required this.status,
    required this.fromDate,
    required this.toDate,
    this.requesterName,
    this.totalDays,
    this.prioList,
  });

  @override
  State<LeaveRequestWidget> createState() => _LeaveRequestWidgetState();
}

class _LeaveRequestWidgetState extends State<LeaveRequestWidget> {
  double screenWidth = 0;
  double lineWidth = 0;
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
    print(widget.prioList?.length);

    screenWidth = MediaQuery.of(context).size.width;
    widget.prioList?.length == 2
        ? lineWidth = screenWidth * 0.65
        : lineWidth = screenWidth / 2 * 0.65;
    final name = widget.requesterName ?? 'Employee';
    final days = widget.totalDays ?? '';
    // Sort prioList by prio ascending
    final sortedPrioList =
        (widget.prioList ?? [])
          ..sort((a, b) => (a['prio'] as int).compareTo(b['prio'] as int));

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
                    '${_formatDate(widget.fromDate)} → ${_formatDate(widget.toDate)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Reason: ${widget.reason}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'STATUS: ${widget.status}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: FileHelper.statusColor(status: widget.status),
              ),
            ),
            const SizedBox(height: 16),
            if (sortedPrioList.isNotEmpty)
              Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      ...List.generate(
                        sortedPrioList.length,
                        (i) => Row(
                          children: [
                            _buildCircle(
                              sortedPrioList[i]['apstatu_text'] ?? "Pending",
                            ),
                            if (i < sortedPrioList.length - 1)
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
                        sortedPrioList
                            .map(
                              (p) => Text(
                                p['prio_text'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircle(String status) {
    Color color;
    switch (status) {
      case "Approved":
        color = Colors.green;
        break;
      case "Rejected":
        color = Colors.red;
        break;
      default:
        color = Colors.orangeAccent;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildConnectingLine() {
    return Container(width: lineWidth, height: 2, color: Colors.grey[400]);
  }
}
