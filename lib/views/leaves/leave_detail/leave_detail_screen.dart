import 'package:chokchey_hr_app/utils/file_helper.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../../models/leave_history_model.dart';
import '../../../widgets/compact_detail_row.dart';
import '../../../widgets/compact_follow_up_button.dart';
import '../../../repositories/leave_detail_repository.dart'; // Add this import

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
  final LeaveDetailRepository _repository =
      LeaveDetailRepository(); // Add repository instance
  bool _isCancelling = false; // Add loading state

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
            FileHelper.getStatusColor(widget.leaveRequest.statu),
            FileHelper.getStatusColor(
              widget.leaveRequest.statu,
            ).withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FileHelper.getStatusColor(
              widget.leaveRequest.statu,
            ).withOpacity(0.3),
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
              FileHelper.getStatusIcon(widget.leaveRequest.statu),
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
                    CompactDetailRow(
                      label: 'Employee',
                      value: widget.leaveRequest.dname,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    CompactDetailRow(
                      label: 'From',
                      value: FileHelper.formatDate(
                        widget.leaveRequest.fromDate,
                      ),
                      icon: Icons.date_range,
                    ),
                    const SizedBox(height: 12),
                    CompactDetailRow(
                      label: 'Applied',
                      value: FileHelper.formatDate(
                        widget.leaveRequest.createdDate,
                      ),
                      icon: Icons.schedule,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right column
              Expanded(
                child: Column(
                  children: [
                    CompactDetailRow(
                      label: 'Type',
                      value: widget.leaveRequest.ltyp,
                      icon: Icons.category,
                    ),
                    const SizedBox(height: 12),
                    CompactDetailRow(
                      label: 'To',
                      value: FileHelper.formatDate(widget.leaveRequest.toDate),
                      icon: Icons.date_range,
                    ),
                    const SizedBox(height: 12),
                    CompactDetailRow(
                      label: 'Duration',
                      value:
                          '${widget.leaveRequest.numleav} day${double.parse(widget.leaveRequest.numleav) > 1 ? 's' : ''}',
                      icon: Icons.access_time,
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

              // Status and Follow-up - UPDATED TO USE GLOBAL WIDGET
              if (priority.isPending && widget.leaveRequest.isPending)
                CompactFollowUpButton(
                  onTap: () => _showFollowUpDialog(priority),
                )
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
    bool isSending = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
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
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        maxLines: 3,
                        enabled: !isSending,
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
                      onPressed:
                          isSending ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isSending
                              ? null
                              : () async {
                                if (messageController.text.trim().isNotEmpty) {
                                  setDialogState(() {
                                    isSending = true;
                                  });

                                  try {
                                    final success = await _repository
                                        .sendFollowUpMessage(
                                          widget.leaveRequest.lreid,
                                          messageController.text.trim(),
                                        );

                                    if (!mounted) return;

                                    Navigator.pop(context);

                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Follow-up sent to ${priority.approverName}',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to send follow-up. Please try again.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (!mounted) return;

                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child:
                          isSending
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Send',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing during loading
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
                onPressed: _isCancelling ? null : () => Navigator.pop(context),
                child: const Text('No'),
              ),
              StatefulBuilder(
                builder:
                    (context, setDialogState) => ElevatedButton(
                      onPressed:
                          _isCancelling
                              ? null
                              : () => _cancelLeaveRequest(setDialogState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child:
                          _isCancelling
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Yes, Cancel',
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
              ),
            ],
          ),
    );
  }

  // Updated method to handle cancel leave request with API call
  Future<void> _cancelLeaveRequest([StateSetter? setDialogState]) async {
    // Update both dialog state and widget state
    if (setDialogState != null) {
      setDialogState(() {
        _isCancelling = true;
      });
    }

    if (mounted) {
      setState(() {
        _isCancelling = true;
      });
    }

    try {
      // Add null check for repository
      if (_repository == null) {
        throw Exception('Repository not initialized');
      }

      final success = await _repository.cancelLeaveRequest(
        widget.leaveRequest.lreid,
      );

      // Update states
      if (setDialogState != null) {
        setDialogState(() {
          _isCancelling = false;
        });
      }

      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }

      if (!mounted) return;

      if (success) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context, true); // Go back to previous screen with result

        // Use a post frame callback to ensure the widget is still mounted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Leave request cancelled successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      } else {
        Navigator.pop(context); // Close dialog

        // Use a post frame callback to ensure the widget is still mounted
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to cancel leave request. Please try again.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (e) {
      // Update states on error
      if (setDialogState != null) {
        setDialogState(() {
          _isCancelling = false;
        });
      }

      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }

      if (!mounted) return;

      Navigator.pop(context); // Close dialog

      // Use a post frame callback to ensure the widget is still mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _showCancelConfirmation(),
              ),
            ),
          );
        }
      });
    }
  }
}
