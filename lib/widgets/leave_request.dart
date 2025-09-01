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
  final String? currentUserName;
  final String? currentUserProfileImageUrl;

  const LeaveRequestWidget({
    super.key,
    required this.reason,
    required this.status,
    required this.fromDate,
    required this.toDate,
    this.requesterName,
    this.totalDays,
    this.prioList,
    this.currentUserName,
    this.currentUserProfileImageUrl,
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

    screenWidth = MediaQuery.of(context).size.width;
    widget.prioList?.length == 2
        ? lineWidth = screenWidth * 0.65
        : lineWidth = screenWidth / 2 * 0.58;
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
                _buildEmployeeAvatar(name),
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

  Widget _buildEmployeeAvatar(String employeeName) {
    // Check if this is the current user's leave request
    final isCurrentUser =
        widget.currentUserName != null &&
        employeeName.toLowerCase() == widget.currentUserName!.toLowerCase();

    if (isCurrentUser &&
        widget.currentUserProfileImageUrl != null &&
        widget.currentUserProfileImageUrl!.isNotEmpty) {
      // Show actual profile image for current user
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent,
        ),
        child: ClipOval(
          child: FadeInImage.assetNetwork(
            placeholder: 'assets/images/profile.png',
            image: widget.currentUserProfileImageUrl!,
            fit: BoxFit.cover,
            imageErrorBuilder: (context, error, stackTrace) {
              return const CircleAvatar(
                backgroundImage: AssetImage('assets/images/profile.png'),
                backgroundColor: Colors.blueAccent,
              );
            },
          ),
        ),
      );
    }
    // else if (isCurrentUser) {
    //   // Current user but no profile image - show default asset image
    //   return const CircleAvatar(
    //     backgroundImage: AssetImage('assets/images/profile.png'),
    //     backgroundColor: Colors.blueAccent,
    //   );
    // }
    else {
      // Show initials avatar for other employees
      return _buildInitialsAvatar(employeeName);
    }
  }

  Widget _buildInitialsAvatar(String employeeName) {
    // Extract initials from employee name
    String getInitials(String name) {
      if (name.isEmpty) return 'E';

      List<String> nameParts = name.trim().split(' ');
      if (nameParts.length == 1) {
        return nameParts[0].substring(0, 1).toUpperCase();
      } else {
        return (nameParts[0].substring(0, 1) +
                nameParts[nameParts.length - 1].substring(0, 1))
            .toUpperCase();
      }
    }

    // Generate a color based on the name
    Color getAvatarColor(String name) {
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.brown,
      ];

      int hash = name.hashCode;
      return colors[hash.abs() % colors.length];
    }

    return CircleAvatar(
      backgroundColor: getAvatarColor(employeeName),
      child: Text(
        getInitials(employeeName),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
