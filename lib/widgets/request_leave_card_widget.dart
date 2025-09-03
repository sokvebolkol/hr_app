import 'package:chokchey_hr_app/utils/file_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/constant.dart';

class RequesterLeaveCardWidget extends StatelessWidget {
  final String requesterName;
  final String positionName;
  final String leaveType;
  final double numLeaveDays;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final DateTime requestDate;
  final VoidCallback? onTap;
  final String? actionText;
  final Color? avatarBackgroundColor;
  final Color? avatarTextColor;

  const RequesterLeaveCardWidget({
    super.key,
    required this.requesterName,
    required this.positionName,
    required this.leaveType,
    required this.numLeaveDays,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.requestDate,
    this.onTap,
    this.actionText = 'Tap to review',
    this.avatarBackgroundColor,
    this.avatarTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserHeader(),
              const SizedBox(height: 12),
              _buildLeaveDetails(),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildReasonSection(),
              ],
              const SizedBox(height: 8),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: avatarBackgroundColor ?? Colors.orange[100],
          radius: 20,
          child: Text(
            FileHelper.abbreviateName(requesterName),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: avatarTextColor ?? Colors.orange[700],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requesterName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                positionName,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildLeaveDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.category_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                leaveType,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '$numLeaveDays day${numLeaveDays > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.date_range_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDateRange(),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Text(
      reason,
      style: TextStyle(color: Colors.grey[700], fontSize: 12),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Requested: ${DateFormat('MMM dd, yyyy').format(requestDate)}',
          style: TextStyle(color: Colors.grey[500], fontSize: 10),
        ),
        if (actionText != null)
          Text(
            actionText!,
            style: TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  String _formatDateRange() {
    if (_isSameDate(fromDate, toDate)) {
      return DateFormat('MMM dd, yyyy').format(fromDate);
    } else {
      return '${DateFormat('MMM dd').format(fromDate)} - ${DateFormat('MMM dd, yyyy').format(toDate)}';
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
