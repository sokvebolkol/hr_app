import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodels/leave_action_viewmodel.dart';

class LeaveActionButtons extends StatelessWidget {
  final String leaveId;
  final String employeeName;
  final String leaveType;
  final int numLeaveDays;
  final DateTime fromDate;
  final DateTime toDate;
  final Function(bool isApprove, String remark, bool success) onAction;
  final LeaveActionViewModel viewModel;

  const LeaveActionButtons({
    super.key,
    required this.leaveId,
    required this.employeeName,
    required this.leaveType,
    required this.numLeaveDays,
    required this.fromDate,
    required this.toDate,
    required this.onAction,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveActionViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.hasActionTaken) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Action completed successfully',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFECECEC),
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
                    viewModel.isRejecting ? 'Rejecting...' : 'Reject',
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
                    viewModel.isApproving ? 'Approving...' : 'Approve',
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  isApprove ? Icons.check_circle : Icons.cancel,
                  color: isApprove ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(isApprove ? 'Approve Leave' : 'Reject Leave'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employee: $employeeName'),
                Text('Leave Type: $leaveType'),
                Text(
                  'Duration: $numLeaveDays day${numLeaveDays != 1 ? 's' : ''}',
                ),
                Text(
                  'Dates: ${DateFormat('MMM dd - dd, yyyy').format(fromDate)}',
                ),
                const SizedBox(height: 16),
                if (!isApprove) ...[
                  const Text(
                    'Rejection Reason (Optional):',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarkController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for rejection...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  isApprove
                      ? 'Are you sure you want to approve this leave request?'
                      : 'Are you sure you want to reject this leave request?',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  bool success;
                  if (isApprove) {
                    success = await viewModel.approveLeave(
                      leaveId: leaveId,
                      remark: remarkController.text.trim(),
                    );
                  } else {
                    success = await viewModel.rejectLeave(
                      leaveId: leaveId,
                      remark: remarkController.text.trim(),
                    );
                  }

                  // Show success/error message
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          viewModel.successMessage ??
                              (isApprove
                                  ? 'Leave request approved successfully'
                                  : 'Leave request rejected successfully'),
                        ),
                        backgroundColor: isApprove ? Colors.green : Colors.red,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          viewModel.errorMessage ?? 'Action failed',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  // Call the callback
                  onAction(isApprove, remarkController.text.trim(), success);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApprove ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(isApprove ? 'Approve' : 'Reject'),
              ),
            ],
          ),
    );
  }
}
