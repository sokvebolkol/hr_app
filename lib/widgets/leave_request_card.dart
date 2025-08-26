import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/constant.dart';
import '../repositories/approver_dashboard_repository.dart';
import '../models/leave_model.dart';

class LeaveRequestCard extends StatelessWidget {
  final dynamic leave; // Can be PendingLeaveRequest or LeaveModel
  final bool isPending;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onTap;

  const LeaveRequestCard({
    super.key,
    required this.leave,
    required this.isPending,
    this.onApprove,
    this.onReject,
    this.onTap,
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
              _buildHeader(),
              const SizedBox(height: 12),
              _buildLeaveDetails(),
              if (_getReason().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _getReason(),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: isPending ? Colors.orange[100] : Colors.green[100],
          radius: 20,
          child: Text(
            _getRequesterName().isNotEmpty
                ? _getRequesterName()[0].toUpperCase()
                : 'U',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isPending ? Colors.orange[700] : Colors.green[700],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getRequesterName(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (isPending && leave is PendingLeaveRequest) ...[
                Text(
                  (leave as PendingLeaveRequest).positionName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ] else if (!isPending && leave is LeaveModel) ...[
                Text(
                  'ID: ${(leave as LeaveModel).eid}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
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
                _getLeaveType(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_getNumDays()} day(s)',
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
                  '${DateFormat('MMM dd').format(_getFromDate())} - ${DateFormat('MMM dd, yyyy').format(_getToDate())}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Requested: ${DateFormat('MMM dd, yyyy').format(_getRequestDate())}',
          style: TextStyle(color: Colors.grey[500], fontSize: 10),
        ),
        if (isPending && onApprove != null && onReject != null)
          GestureDetector(
            onTap: () {
              // Prevent parent GestureDetector from triggering
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          )
        else
          Text(
            'Tap to view details',
            style: TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  // Helper methods to extract data from either PendingLeaveRequest or LeaveModel
  String _getRequesterName() {
    if (leave is PendingLeaveRequest) {
      return (leave as PendingLeaveRequest).requesterName;
    } else if (leave is LeaveModel) {
      return (leave as LeaveModel).dname;
    }
    return '';
  }

  String _getLeaveType() {
    if (leave is PendingLeaveRequest) {
      return (leave as PendingLeaveRequest).ltyp;
    } else if (leave is LeaveModel) {
      // Assuming LeaveModel has a ltyp field or similar
      return 'Leave'; // You may need to adjust this based on your LeaveModel
    }
    return '';
  }

  String _getNumDays() {
    if (leave is PendingLeaveRequest) {
      return (leave as PendingLeaveRequest).numLeaveDays.toString();
    } else if (leave is LeaveModel) {
      return (leave as LeaveModel).numleav;
    }
    return '0';
  }

  DateTime _getFromDate() {
    if (leave is PendingLeaveRequest) {
      return (leave as PendingLeaveRequest).fromDate;
    } else if (leave is LeaveModel) {
      return DateTime.tryParse((leave as LeaveModel).frdat) ?? DateTime.now();
    }
    return DateTime.now();
  }

  DateTime _getToDate() {
    if (leave is PendingLeaveRequest) {
      return (leave as PendingLeaveRequest).toDate;
    } else if (leave is LeaveModel) {
      return DateTime.tryParse((leave as LeaveModel).todat) ?? DateTime.now();
    }
    return DateTime.now();
  }

  DateTime _getRequestDate() {
    if (leave is PendingLeaveRequest) {
      return (leave as PendingLeaveRequest).requestDate;
    } else if (leave is LeaveModel) {
      return DateTime.tryParse((leave as LeaveModel).createdate) ??
          DateTime.now();
    }
    return DateTime.now();
  }

  String _getReason() {
    if (leave is PendingLeaveRequest) {
      return (leave as PendingLeaveRequest).reason;
    } else if (leave is LeaveModel) {
      return (leave as LeaveModel).reason;
    }
    return '';
  }
}
