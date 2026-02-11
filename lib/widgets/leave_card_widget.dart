import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/material.dart';
import '../utils/file_helper.dart';
import 'calendar_card_widget.dart';

class LeaveCardWidget extends StatefulWidget {
  final String reason;
  final String status;
  final String totalLabel;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final String? totalDays;
  final double? lineWidth;
  final List<Map<String, dynamic>>? prioList;

  const LeaveCardWidget({
    super.key,
    required this.reason,
    required this.status,
    required this.totalLabel,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    this.totalDays,
    this.lineWidth,
    this.prioList,
  });

  @override
  State<LeaveCardWidget> createState() => _LeaveCardWidgetState();
}

class _LeaveCardWidgetState extends State<LeaveCardWidget> {
  double screenWidth = 0;
  double lineWidth = 0;

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    lineWidth =
        widget.lineWidth ??
        (widget.prioList?.length == 2
            ? screenWidth * 0.731
            : (screenWidth / 2) * 0.70);
            
    final days = widget.totalDays ?? '';
    // Sort prioList by prio ascending
    final sortedPrioList =
        (widget.prioList ?? [])
          ..sort((a, b) => (a['prio'] as int).compareTo(b['prio'] as int));

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CalendarCardWidget(
                    day: DateTime.parse(widget.fromDate).day,
                    month: DateTime.parse(widget.fromDate).month,
                    width: 40,
                    height: 60,
                    isBlackOrWhiteCalendar: true,
                    borderRadius: 7,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.reason,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        days.isNotEmpty
                            ? '${widget.totalLabel} $days day(s)'
                            : '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: FileHelper()
                              .getLeaveTypeColor(widget.leaveType)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: FileHelper()
                                .getLeaveTypeColor(widget.leaveType)
                                .withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          widget.leaveType,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: FileHelper().getLeaveTypeColor(
                              widget.leaveType,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                widget.status == "Pending" ? "Pending ..." : widget.status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FileHelper.statusColor(status: widget.status),
                ),
              ),
            ),
            if (sortedPrioList.isNotEmpty)
              Column(
                children: [
                  Row(
                    children: [
                      ...List.generate(
                        sortedPrioList.length,
                        (i) => Row(
                          children: [
                            _buildCircle(
                              sortedPrioList[i]['apstatu_text'] ?? "Pending...",
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
                    children: List.generate(sortedPrioList.length, (index) {
                      final p = sortedPrioList[index];

                      return sortedPrioList.length == 3
                          ? Container(
                            margin:
                                (sortedPrioList.length == 3 && index == 1)
                                    ? const EdgeInsets.only(left: 40, right: 85)
                                    : EdgeInsets.zero,
                            child: Text(
                              p['prio_text'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          )
                          : Container(
                            margin:
                                (sortedPrioList.length == 2 && index == 1)
                                    ? EdgeInsets.only(left: screenWidth * 0.55)
                                    : EdgeInsets.zero,
                            child: Text(
                              p['prio_text'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          );
                    }),
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
        color = logoPink;
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
