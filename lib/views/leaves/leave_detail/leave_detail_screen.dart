import 'package:chokchey_hr_app/utils/file_helper.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../../models/leave_history_model.dart';
import '../../../widgets/compact_detail_row.dart';
import '../../../widgets/compact_follow_up_button.dart';
import '../../../widgets/compact_status_card.dart';
import '../../../widgets/action_buttons_card.dart'; // Add this import
import '../../../repositories/leave_detail_repository.dart';
import '../update_leave/update_leave_screen.dart';

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
  final LeaveDetailRepository _repository = LeaveDetailRepository();
  bool _isCancelling = false;

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
              // Compact Status Header - UPDATED TO USE GLOBAL WIDGET
              _buildCompactStatusCard(),
              const SizedBox(height: 16),

              // Combined Details and Approval Flow
              _buildMainContentCard(),

              const SizedBox(height: 16),

              // Document Support Section (if available)
              if (_hasDocumentSupport()) _buildDocumentSupportCard(),

              const SizedBox(height: 16),

              // Action Buttons (if pending)
              if (widget.leaveRequest.isPending) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // Updated to use global widget
  Widget _buildCompactStatusCard() {
    return CompactStatusCard(
      status: widget.leaveRequest.statu,
      statusText: widget.leaveRequest.statusText,
      id: widget.leaveRequest.lreid,
      duration:
          '${widget.leaveRequest.numleav} day${double.parse(widget.leaveRequest.numleav) > 1 ? 's' : ''}',
      durationType: widget.leaveRequest.isFullDay ? 'Full Day' : 'Half Day',
      hasDocument: _hasDocumentSupport(),
    );
  }

  // Check if leave request has document support
  bool _hasDocumentSupport() {
    return widget.leaveRequest.hasDocument == true;
  }

  // Build document support card - RESTORED
  Widget _buildDocumentSupportCard() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Document Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Check if document URL exists
            if (widget.leaveRequest.documentUrl != null &&
                widget.leaveRequest.documentUrl!.isNotEmpty)
              _buildDocumentImage()
            else
              _buildNoDocumentPlaceholder(),
          ],
        ),
      ),
    );
  }

  // Build document image with preview - RESTORED
  Widget _buildDocumentImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.leaveRequest.documentUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                  const SizedBox(height: 8),
                  const Text('Loading document...'),
                ],
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load document',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Build placeholder when no document is available - RESTORED
  Widget _buildNoDocumentPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Document Expected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This leave type requires supporting documents, but none were uploaded or document failed to load',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
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

          // Vertical list of approvers
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

  // Updated to use global widget
  Widget _buildActionButtons() {
    return ActionButtonsCard(
      layout: ButtonLayout.row,
      spacing: 16,
      buttons: [
        ActionButtonData(
          label: 'Update',
          icon: Icons.edit,
          onPressed: _navigateToUpdateScreen,
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        ActionButtonData(
          label: 'Cancel',
          icon: Icons.cancel_outlined,
          onPressed: _showCancelConfirmation,
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          isLoading: _isCancelling,
        ),
      ],
    );
  }

  // Navigate to update screen
  Future<void> _navigateToUpdateScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UpdateLeaveScreen(leaveRequest: widget.leaveRequest),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave request updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Show cancel confirmation dialog
  void _showCancelConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
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
                      onPressed:
                          _isCancelling
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                      child: const Text('No'),
                    ),
                    ElevatedButton(
                      onPressed:
                          _isCancelling
                              ? null
                              : () => _handleCancelRequest(
                                dialogContext,
                                setDialogState,
                              ),
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
                  ],
                ),
          ),
    );
  }

  Future<void> _handleCancelRequest(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    try {
      setDialogState(() {
        _isCancelling = true;
      });

      final success = await _repository.cancelLeaveRequest(
        widget.leaveRequest.lreid,
      );

      setDialogState(() {
        _isCancelling = false;
      });

      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }

      if (success) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }

        _showSnackBar('Leave request cancelled successfully', Colors.green);
      } else {
        _showSnackBar(
          'Failed to cancel leave request. Please try again.',
          Colors.red,
        );
      }
    } catch (e) {
      setDialogState(() {
        _isCancelling = false;
      });

      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }

      _showErrorSnackBar(e.toString());
    }
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

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showErrorSnackBar(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
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
  }
}
