import 'package:flutter/material.dart';

class ApprovalWorkflowWidget extends StatelessWidget {
  final List<ApprovalItemData> approvalList;
  final String title;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final Widget Function(ApprovalItemData approval, bool isLast)?
  customApprovalBuilder;

  const ApprovalWorkflowWidget({
    super.key,
    required this.approvalList,
    this.title = 'Approvers',
    this.titleIcon = Icons.approval,
    this.titleIconColor = Colors.orange,
    this.customApprovalBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (approvalList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort approval list by priority
    final sortedApprovals = [...approvalList];
    sortedApprovals.sort((a, b) => a.priority.compareTo(b.priority));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(titleIcon, color: titleIconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Vertical list of approvers
            ...sortedApprovals.asMap().entries.map((entry) {
              final index = entry.key;
              final approval = entry.value;
              final isLast = index == sortedApprovals.length - 1;

              // Use custom builder if provided, otherwise use default
              return customApprovalBuilder?.call(approval, isLast) ??
                  _buildVerticalApprovalStep(approval, isLast);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalApprovalStep(ApprovalItemData approval, bool isLast) {
    Color statusColor = _getApprovalStatusColor(approval.status);
    IconData statusIcon = _getApprovalStatusIcon(approval.status);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.only(top: 8),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Approval details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Approver info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              approval.approverName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              approval.roleText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          approval.statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Approval remark (if available)
                  if (approval.remark != null &&
                      approval.remark!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Remark:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            approval.remark!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }

  Color _getApprovalStatusColor(int status) {
    switch (status) {
      case 1: // Approved
        return Colors.green;
      case 0: // Rejected
        return Colors.red;
      case 2: // Pending
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getApprovalStatusIcon(int status) {
    switch (status) {
      case 1: // Approved
        return Icons.check_circle;
      case 0: // Rejected
        return Icons.cancel;
      case 2: // Pending
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}

// Data class for approval items
class ApprovalItemData {
  final String approverName;
  final int priority;
  final int status;
  final String statusText;
  final String roleText;
  final String? remark;

  ApprovalItemData({
    required this.approverName,
    required this.priority,
    required this.status,
    required this.statusText,
    required this.roleText,
    this.remark,
  });

  // Factory constructors for different model types
  factory ApprovalItemData.fromPriorityModel(dynamic model) {
    return ApprovalItemData(
      approverName: model.approverName ?? '',
      priority: model.prio ?? 0,
      status: model.apstatu ?? 0,
      statusText: model.apstatuText ?? '',
      roleText: model.prioText ?? '',
      remark: model.remark,
    );
  }

  factory ApprovalItemData.fromApprovalItem(dynamic model) {
    return ApprovalItemData(
      approverName: model.approverName ?? '',
      priority: model.prio ?? 0,
      status: model.apstatu ?? 0,
      statusText: model.apstatuText ?? '',
      roleText: model.prioText ?? '',
      remark: model.remark,
    );
  }

  factory ApprovalItemData.fromCeoApprovalItem(dynamic model) {
    return ApprovalItemData(
      approverName: model.approverName ?? '',
      priority: model.prio ?? 0,
      status: model.apstatu ?? 0,
      statusText: model.apstatuText ?? '',
      roleText: model.prioText ?? '',
      remark: model.remark,
    );
  }

  factory ApprovalItemData.fromMap(Map<String, dynamic> map) {
    return ApprovalItemData(
      approverName: map['approver_name'] ?? '',
      priority: map['prio'] ?? 0,
      status: map['apstatu'] ?? 0,
      statusText: map['apstatu_text'] ?? '',
      roleText: map['prio_text'] ?? '',
      remark: map['remark'],
    );
  }
}
