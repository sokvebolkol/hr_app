import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/constant.dart';
import '../../models/ceo_dashboard_model.dart';
import '../../repositories/profile_repository.dart';
import '../../utils/file_helper.dart';
import '../../viewmodels/attendance_adjustment_action_viewmodel.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../widgets/approvalworkflowwidget.dart';
import '../../widgets/attendance_action_widget.dart';

class AttendanceAdjustmentApprovalDetailScreen extends StatefulWidget {
  final AttendanceAdjustmentRequest request;
  final bool isPending;

  const AttendanceAdjustmentApprovalDetailScreen({
    super.key,
    required this.request,
    required this.isPending,
  });

  @override
  State<AttendanceAdjustmentApprovalDetailScreen> createState() =>
      _AttendanceAdjustmentApprovalDetailScreenState();
}

class _AttendanceAdjustmentApprovalDetailScreenState
    extends State<AttendanceAdjustmentApprovalDetailScreen> {
  Language language = Language();

  String? _currentUserName;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    final languageLogic = LanguageLogic();
    await languageLogic.initialize();
    if (mounted) {
      setState(() {
        language = languageLogic.language;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final profile = await ProfileRepository().getUserProfile();
    if (mounted) {
      setState(() {
        _currentUserName = profile?.fullName;
        _isLoadingUser = false;
      });
    }
  }

  /// Returns true if the logged-in user has already acted on this request.
  bool get _hasCurrentUserAlreadyActed {
    if (_currentUserName == null) return false;
    return widget.request.approverList.any(
      (item) =>
          item.approverName.toLowerCase() == _currentUserName!.toLowerCase() &&
          item.approvalStatus != 2, // 2 = pending
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AttendanceAdjustmentActionViewModel(),
      child: Consumer<AttendanceAdjustmentActionViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: secondary,
              foregroundColor: Colors.white,
              centerTitle: false,
              title: Text(
                language.adjustmentDetail,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeCard(viewModel),
                  _buildAdjustmentDetailsCard(viewModel),
                  const SizedBox(height: 16),
                  if (widget.request.documentUrl != null &&
                      widget.request.documentUrl!.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
                      child: _buildSupportingDocumentCard(),
                    ),
                  ],
                  if (widget.request.approverList.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(left: 16, right: 16),
                      child: ApprovalWorkflowWidget(
                        title: language.userApprovers,
                        approvalList:
                            widget.request.approverList
                                .map(
                                  (item) => ApprovalItemData(
                                    approverName: item.approverName,
                                    priority: item.priority,
                                    status: item.approvalStatus,
                                    statusText: item.approvalStatusText,
                                    roleText: item.priorityText,
                                    remark: item.remark,
                                  ),
                                )
                                .toList(),
                        titleIconColor: secondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 100), // Space for floating buttons
                ],
              ),
            ),
            floatingActionButton:
                widget.isPending &&
                        !_isLoadingUser &&
                        !_hasCurrentUserAlreadyActed
                    ? Consumer<AttendanceAdjustmentActionViewModel>(
                      builder: (context, vm, child) {
                        return AttendanceActionButtons(
                          adjustmentId: widget.request.id.toString(),
                          employeeName: widget.request.requesterName,
                          adjustmentType: widget.request.adjustType,
                          adjustDate: widget.request.adjustDate,
                          onAction: _handleAttendanceAction,
                          viewModel: vm,
                        );
                      },
                    )
                    : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }

  void _handleAttendanceAction(bool isApprove, String remark, bool success) {
    if (success) {
      // Navigate back immediately with refresh instruction
      Navigator.pop(context, {
        'action': isApprove ? 'approve' : 'reject',
        'remark': remark,
        'success': true,
        'refresh': true,
        'adjustmentId': widget.request.id,
      });
    }
  }

  Widget _buildEmployeeCard(AttendanceAdjustmentActionViewModel viewModel) {
    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1a5f7a),
              secondary,
              secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header Section with Avatar and Status
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Text(
                          widget.request.requesterName.isNotEmpty
                              ? widget.request.requesterName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: secondary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                viewModel.hasActionTaken
                                    ? Colors.orange
                                    : FileHelper.getStatusColor(
                                      widget.request.statusText,
                                    ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            viewModel.hasActionTaken
                                ? Icons.check
                                : _getStatusIcon(),
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request.requesterName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${language.staffId}: ${widget.request.staffId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (viewModel.hasActionTaken
                              ? Colors.orange
                              : FileHelper.getStatusColor(
                                widget.request.statusText,
                              ))
                          .withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          viewModel.hasActionTaken
                              ? Icons.check_circle
                              : _getStatusIcon(),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          viewModel.hasActionTaken
                              ? language.processed
                              : widget.request.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Employee Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.employeeInformation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.location_on_outlined,
                    language.branch,
                    widget.request.branchFullName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.work_outline,
                    language.position,
                    widget.request.positionName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.business_outlined,
                    language.department,
                    widget.request.departmentName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.email_outlined,
                    language.email,
                    widget.request.email,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    switch (widget.request.statusText.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildAdjustmentDetailsCard(
    AttendanceAdjustmentActionViewModel viewModel,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              language.adjustmentType,
              widget.request.adjustType,
              Icons.edit_calendar,
            ),
            _buildDetailRow(
              language.adjustmentDate,
              DateFormat(
                'EEEE, MMMM dd, yyyy',
              ).format(widget.request.adjustDate),
              Icons.date_range,
            ),
            _buildDetailRow(
              language.requestedOn,
              DateFormat(
                'MMMM dd, yyyy hh:mm a',
              ).format(widget.request.requestDate),
              Icons.access_time,
            ),

            if (widget.request.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                language.reason,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  widget.request.reason,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportingDocumentCard() {
    return FileHelper.buildSupportingDocumentCard(
      context,
      widget.request.documentUrl!,
      accentColor: secondary,
    );
  }
}
