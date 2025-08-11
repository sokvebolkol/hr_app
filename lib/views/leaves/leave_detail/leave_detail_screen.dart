import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/constant.dart';
import '../../../models/leave_history_model.dart';

class LeaveDetailScreen extends StatefulWidget {
  final LeaveHistoryModel leaveRequest;

  const LeaveDetailScreen({super.key, required this.leaveRequest});

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Leave Details',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Compact Status Header
              _buildCompactStatusCard(),
              const SizedBox(height: 16),

              // Combined Details and Approval Flow
              _buildMainContentCard(),

              const SizedBox(height: 16),

              // Action Buttons (if needed)
              if (widget.leaveRequest.isPending) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor(widget.leaveRequest.statu),
            _getStatusColor(widget.leaveRequest.statu).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(widget.leaveRequest.statu).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(widget.leaveRequest.statu),
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.leaveRequest.statusText,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.leaveRequest.lreid}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Quick info on the right
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${widget.leaveRequest.numleav} day${widget.leaveRequest.numberOfDays > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.leaveRequest.isFullDay ? 'Full Day' : 'Half Day',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Details Section
          _buildDetailsSection(),

          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 1,
            color: Colors.grey[200],
          ),

          // Approval Flow Section
          _buildApprovalSection(),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Leave Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildCompactDetailRow(
                      'Employee',
                      widget.leaveRequest.dname,
                      Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _buildCompactDetailRow(
                      'From',
                      _formatCompactDate(widget.leaveRequest.fromDate),
                      Icons.date_range,
                    ),
                    const SizedBox(height: 12),
                    _buildCompactDetailRow(
                      'Applied',
                      _formatCompactDate(widget.leaveRequest.createdDate),
                      Icons.schedule,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right column
              Expanded(
                child: Column(
                  children: [
                    _buildCompactDetailRow(
                      'Type',
                      widget.leaveRequest.ltyp,
                      Icons.category,
                    ),
                    const SizedBox(height: 12),
                    _buildCompactDetailRow(
                      'To',
                      _formatCompactDate(widget.leaveRequest.toDate),
                      Icons.date_range,
                    ),
                    const SizedBox(height: 12),
                    _buildCompactDetailRow(
                      'Duration',
                      '${widget.leaveRequest.numleav} day${widget.leaveRequest.numberOfDays > 1 ? 's' : ''}',
                      Icons.access_time,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Reason (full width if not empty)
          if (widget.leaveRequest.reason.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes, size: 16, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.leaveRequest.reason,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactDetailRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSection() {
    final sortedPriorities = [...widget.leaveRequest.prioList];
    sortedPriorities.sort((a, b) => a.prio.compareTo(b.prio));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.approval, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'User Approvers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Vertical list of approvers (more compact)
          ...sortedPriorities.asMap().entries.map((entry) {
            final index = entry.key;
            final priority = entry.value;
            final isLast = index == sortedPriorities.length - 1;
            return _buildVerticalApprovalStep(priority, isLast, index);
          }),
        ],
      ),
    );
  }

  Widget _buildVerticalApprovalStep(
    PriorityModel priority,
    bool isLast,
    int stepIndex,
  ) {
    Color statusColor;
    IconData statusIcon;

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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              // Step indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Approver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      priority.prioText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priority.approverName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Status and Follow-up
              if (priority.isPending && widget.leaveRequest.isPending)
                _buildCompactFollowUpButton(priority)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    priority.apstatuText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHorizontalApprovalStep(
    PriorityModel priority,
    bool isLast,
    int stepIndex,
  ) {
    Color statusColor;
    IconData statusIcon;

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

    return Row(
      children: [
        Container(
          width: 130, // Reduced width
          padding: const EdgeInsets.all(10), // Reduced padding
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Important: prevent overflow
            children: [
              // Step indicator
              Container(
                width: 36, // Reduced size
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 12, // Reduced font size
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6), // Reduced spacing
              // Approver info
              Text(
                priority.prioText.split(' ').first, // First word only
                style: TextStyle(
                  fontSize: 9, // Reduced font size
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                priority.approverName.split(' ').first, // First name only
                style: const TextStyle(
                  fontSize: 11, // Reduced font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Status and Follow-up
              Flexible(
                // Use Flexible to prevent overflow
                child:
                    priority.isPending && widget.leaveRequest.isPending
                        ? _buildCompactFollowUpButton(priority)
                        : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priority.apstatuText,
                            style: TextStyle(
                              fontSize: 9, // Reduced font size
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
              ),
            ],
          ),
        ),

        // Arrow connector
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
            ), // Reduced padding
            child: Icon(Icons.arrow_forward, color: Colors.grey[400], size: 18),
          ),
      ],
    );
  }

  Widget _buildCompactFollowUpButton(PriorityModel priority) {
    return GestureDetector(
      onTap: () => _showFollowUpDialog(priority),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ), // Reduced padding
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue, Colors.blue.shade600]),
          borderRadius: BorderRadius.circular(6), // Reduced border radius
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.message,
              size: 8,
              color: Colors.white,
            ), // Reduced icon size
            SizedBox(width: 3), // Reduced spacing
            Text(
              'Follow Up',
              style: TextStyle(
                fontSize: 8, // Reduced font size
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showCancelConfirmation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text(
            'Cancel Request',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showFollowUpDialog(PriorityModel priority) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.message,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Follow Up', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priority.approverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        priority.prioText,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter your message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (messageController.text.trim().isNotEmpty) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Follow-up sent to ${priority.approverName}',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text(
                  'Send',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Cancel Request'),
              ],
            ),
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
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Leave request cancelled'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Yes, Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  String _formatCompactDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
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
