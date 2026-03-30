import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/file_helper.dart';

class PendingApprovalRequestWidget extends StatefulWidget {
  final String reason;
  final String? label;
  final String status;
  final String fromDate;
  final String toDate;
  final String? leaveDate;
  final String? requesterName;
  final String? position;
  final String? leaveType;
  final String? totalDays;
  final bool? isLeaveRequest;
  final String? currentUserName;
  final String? currentUserProfileImageUrl;
  final String? empProfileImage;

  const PendingApprovalRequestWidget({
    super.key,
    required this.reason,
    this.label = 'Reason: ',
    required this.status,
    required this.fromDate,
    required this.toDate,
    this.leaveDate,
    this.requesterName,
    this.position,
    this.leaveType,
    this.isLeaveRequest = true,
    this.totalDays,
    this.currentUserName,
    this.currentUserProfileImageUrl,
    this.empProfileImage,
  });

  @override
  State<PendingApprovalRequestWidget> createState() =>
      _LeaveRequestWidgetState();
}

class _LeaveRequestWidgetState extends State<PendingApprovalRequestWidget> {
  double screenWidth = 0;
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

    final name = widget.requesterName ?? 'Employee';
    final days = widget.totalDays ?? '';
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
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (widget.position != null &&
                          widget.position!.isNotEmpty)
                        Text(
                          widget.position!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
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
                          widget.leaveType!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            overflow: TextOverflow.ellipsis,
                            color: FileHelper().getLeaveTypeColor(
                              widget.leaveType,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.isLeaveRequest == true)
                        Text(
                          '$days day(s)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                    ],
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
                widget.isLeaveRequest!
                    ? Expanded(
                      flex: 2,
                      child: RichText(
                        text: TextSpan(
                          text: widget.leaveDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '${_formatDate(widget.fromDate)} → ${_formatDate(widget.toDate)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : Expanded(
                      flex: 2,
                      child: Text(
                        FileHelper.formatDate(DateTime.parse(widget.fromDate)),
                        style: const TextStyle(
                          fontSize: 12,
                          color: secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: widget.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: widget.reason,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        widget.status == 'Pending'
                            ? FontAwesomeIcons.clock
                            : Icons.check_circle,
                        size: 16,
                        color: FileHelper.statusColor(status: widget.status),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: FileHelper.statusColor(status: widget.status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
    } else if (widget.empProfileImage != null &&
        widget.empProfileImage!.isNotEmpty) {
      // Show actual profile image for other employees if available
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
            image: widget.empProfileImage!,
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
    } else {
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
