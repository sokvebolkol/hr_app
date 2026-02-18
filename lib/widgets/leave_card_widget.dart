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
  @override
  Widget build(BuildContext context) {
    final days = widget.totalDays ?? '';

    // Sort prioList by prio ascending
    final sortedPrioList = List<Map<String, dynamic>>.from(
      widget.prioList ?? [],
    )..sort((a, b) => (a['prio'] as int).compareTo(b['prio'] as int));

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP ROW
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
                      Text(
                        widget.reason,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      if (days.isNotEmpty)
                        Text(
                          '${widget.totalLabel} $days day(s)',
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

            /// STATUS TEXT
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                widget.status == "Pending" ? "Pending ..." : widget.status,

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: FileHelper.statusColor(status: widget.status),
                ),
              ),
            ),

            /// STEP PROGRESS
            if (sortedPrioList.isNotEmpty)
              Column(
                children: [
                  /// CIRCLES + LINES
                  Row(
                    children: List.generate(sortedPrioList.length * 2 - 1, (
                      index,
                    ) {
                      if (index.isEven) {
                        final i = index ~/ 2;

                        return _buildCircle(
                          sortedPrioList[i]['apstatu_text'] ?? "Pending...",
                        );
                      } else {
                        return Expanded(child: _buildConnectingLine());
                      }
                    }),
                  ),

                  const SizedBox(height: 8),

                  /// LABELS
                  Row(
                    children: List.generate(sortedPrioList.length, (index) {
                      return Expanded(
                        child: Text(
                          sortedPrioList[index]['prio_text'] ?? '',

                          textAlign:
                              index == 0
                                  ? TextAlign.left
                                  : index == sortedPrioList.length - 1
                                  ? TextAlign.right
                                  : TextAlign.center,

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

  /// BUILD CIRCLE
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

  /// BUILD CONNECTING LINE (FULLY FLEXIBLE)
  Widget _buildConnectingLine() {
    return Container(height: 2, color: Colors.grey[400]);
  }
}
