import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/leave_action_viewmodel.dart';

class LeaveActionButtons extends StatelessWidget {
  final String leaveId;
  final String approve;
  final String reject;
  final String employeeName;
  final String leaveType;
  final double numLeaveDays;
  final DateTime fromDate;
  final DateTime toDate;
  final Function(bool isApprove, String remark, bool success) onAction;
  final LeaveActionViewModel viewModel;
  final bool showApproveRemark;

  const LeaveActionButtons({
    super.key,
    required this.leaveId,
    required this.approve,
    required this.reject,
    required this.employeeName,
    required this.leaveType,
    required this.numLeaveDays,
    required this.fromDate,
    required this.toDate,
    required this.onAction,
    required this.viewModel,
    this.showApproveRemark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveActionViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECECEC),
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
          child: Row(
            children: [
              Expanded(
                child: FloatingActionButton.extended(
                  heroTag: "reject_${leaveId}",
                  onPressed:
                      viewModel.isProcessing
                          ? null
                          : () => _showActionDialog(context, false),
                  backgroundColor:
                      viewModel.isProcessing ? Colors.grey : Colors.red,
                  icon:
                      viewModel.isRejecting
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.close, color: Colors.white),
                  label: Text(
                    viewModel.isRejecting ? 'Rejecting...' : reject,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FloatingActionButton.extended(
                  heroTag: "approve_${leaveId}",
                  onPressed:
                      viewModel.isProcessing
                          ? null
                          : () => _showActionDialog(context, true),
                  backgroundColor:
                      viewModel.isProcessing ? Colors.grey : Colors.green,
                  icon:
                      viewModel.isApproving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    viewModel.isApproving ? 'Approving...' : approve,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActionDialog(BuildContext context, bool isApprove) {
    final TextEditingController remarkController = TextEditingController();
    final actionColor = isApprove ? Colors.green : Colors.red;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with gradient background
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                actionColor.withOpacity(0.8),
                                actionColor,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
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
                                  isApprove
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isApprove ? approve : reject,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Confirm your decision',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Leave Information Card
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: actionColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: actionColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildInfoRow(
                                      Icons.person_outline,
                                      'Employee',
                                      employeeName,
                                      actionColor,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.category_outlined,
                                      'Leave Type',
                                      leaveType,
                                      actionColor,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.access_time,
                                      'Duration',
                                      '$numLeaveDays day${numLeaveDays != 1 ? 's' : ''}',
                                      actionColor,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      Icons.calendar_today_outlined,
                                      'Dates',
                                      DateFormat(
                                        'MMM dd - dd, yyyy',
                                      ).format(fromDate),
                                      actionColor,
                                    ),
                                  ],
                                ),
                              ),

                              // Remark field
                              if (!isApprove || showApproveRemark) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.edit_note,
                                      size: 20,
                                      color: actionColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isApprove
                                          ? 'Approval Remark (Optional)'
                                          : 'Rejection Remark (Required)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: remarkController,
                                  maxLines: 3,
                                  minLines: 3,
                                  onChanged: (_) => setDialogState(() {}),
                                  decoration: InputDecoration(
                                    hintText:
                                        isApprove
                                            ? 'Add a note for approval...'
                                            : 'Add a reason for rejection...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: actionColor,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Actions
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      (!isApprove &&
                                              remarkController.text
                                                  .trim()
                                                  .isEmpty)
                                          ? null
                                          : () async {
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            Navigator.pop(dialogContext);
                                            bool success;
                                            if (isApprove) {
                                              success = await viewModel
                                                  .approveLeave(
                                                    leaveId: leaveId,
                                                    remark:
                                                        remarkController.text
                                                            .trim(),
                                                  );
                                            } else {
                                              success = await viewModel
                                                  .rejectLeave(
                                                    leaveId: leaveId,
                                                    remark:
                                                        remarkController.text
                                                            .trim(),
                                                  );
                                            }

                                            if (!success) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    viewModel.errorMessage ??
                                                        'Action failed',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                            // Call the callback — parent handles navigation
                                            onAction(
                                              isApprove,
                                              remarkController.text.trim(),
                                              success,
                                            );
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        (!isApprove &&
                                                remarkController.text
                                                    .trim()
                                                    .isEmpty)
                                            ? Colors.grey[300]
                                            : actionColor,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[300],
                                    disabledForegroundColor: Colors.grey[500],
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isApprove ? Icons.check : Icons.close,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isApprove ? 'Approve' : 'Reject',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
