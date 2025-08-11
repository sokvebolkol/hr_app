import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/constant.dart';
import '../../../models/leave_history_model.dart';

class LeaveDetailScreen extends StatelessWidget {
  final LeaveHistoryModel leaveRequest;

  const LeaveDetailScreen({super.key, required this.leaveRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Leave Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildApprovalFlowCard(),
            const SizedBox(height: 20),
            if (leaveRequest.isPending) _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              _getStatusColor(leaveRequest.statu),
              _getStatusColor(leaveRequest.statu).withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(leaveRequest.statu),
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              leaveRequest.statusText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Request ID: ${leaveRequest.lreid}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Leave Type', leaveRequest.ltyp, Icons.category),
            _buildDetailRow('Employee', leaveRequest.dname, Icons.person),
            _buildDetailRow(
              'Duration',
              leaveRequest.isFullDay ? 'Full Day' : 'Half Day',
              leaveRequest.isFullDay ? Icons.wb_sunny : Icons.schedule,
            ),
            _buildDetailRow(
              'Number of Days',
              '${leaveRequest.numleav} day${leaveRequest.numberOfDays > 1 ? 's' : ''}',
              Icons.calendar_today,
            ),
            _buildDetailRow(
              'From Date',
              _formatDate(leaveRequest.fromDate),
              Icons.date_range,
            ),
            _buildDetailRow(
              'To Date',
              _formatDate(leaveRequest.toDate),
              Icons.date_range,
            ),
            _buildDetailRow(
              'Applied Date',
              _formatDate(leaveRequest.createdDate),
              Icons.schedule,
            ),
            if (leaveRequest.reason.isNotEmpty)
              _buildDetailRow(
                'Reason',
                leaveRequest.reason,
                Icons.notes,
                isLongText: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isLongText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: isLongText ? null : 1,
                  overflow: isLongText ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalFlowCard() {
    // Sort priorities by priority level
    final sortedPriorities = [...leaveRequest.prioList];
    sortedPriorities.sort((a, b) => a.prio.compareTo(b.prio));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approval Flow',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedPriorities.asMap().entries.map((entry) {
              final index = entry.key;
              final priority = entry.value;
              final isLast = index == sortedPriorities.length - 1;

              return _buildApprovalStep(priority, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalStep(PriorityModel priority, bool isLast) {
    Color statusColor;
    IconData statusIcon;
    String statusText = priority.apstatuText;

    if (priority.isApproved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (priority.isRejected) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priority.prioText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Container(
            margin: const EdgeInsets.only(left: 19, top: 8, bottom: 8),
            width: 2,
            height: 30,
            color: Colors.grey[300],
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showCancelConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.cancel),
            label: const Text(
              'Cancel Request',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Leave Request'),
            content: const Text(
              'Are you sure you want to cancel this leave request? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement cancel functionality
                  Navigator.pop(context);
                  Navigator.pop(context, true); // Return to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Leave request cancelled'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '0':
        return Colors.red;
      case '1':
        return Colors.green;
      case '2':
        return Colors.orange;
      case '3':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case '0':
        return Icons.cancel;
      case '1':
        return Icons.check_circle;
      case '2':
        return Icons.schedule;
      case '3':
        return Icons.block;
      default:
        return Icons.help;
    }
  }
}
