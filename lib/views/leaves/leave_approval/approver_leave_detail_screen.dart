import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../constants/constant.dart';
import '../../../localization/language.dart';
import '../../../localization/language_logic.dart';
import '../../../models/ceo_dashboard_model.dart';
import '../../../repositories/profile_repository.dart';
import '../../../utils/file_helper.dart';
import '../../../widgets/approvalworkflowwidget.dart';
import '../../../widgets/leave_action_widget.dart';
import '../../../viewmodels/leave_action_viewmodel.dart';

class ApproverLeaveDetailScreen extends StatefulWidget {
  final LeaveRequest leave;
  final bool isPending;
  final VoidCallback? onActionComplete;

  const ApproverLeaveDetailScreen({
    super.key,
    required this.leave,
    this.isPending = false,
    this.onActionComplete,
  });

  @override
  State<ApproverLeaveDetailScreen> createState() =>
      _ApproverLeaveDetailScreenState();
}

class _ApproverLeaveDetailScreenState extends State<ApproverLeaveDetailScreen> {
  String? _currentUserName;
  bool _isLoadingUser = true;
  bool _isNavigating = false;
  Language language = LanguageLogic().language;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    LanguageLogic().addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LanguageLogic().removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {
      language = LanguageLogic().language;
    });
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

  /// Returns true if the logged-in user has already approved or rejected
  /// this leave (i.e. their entry in prioList is no longer pending).
  bool get _hasCurrentUserAlreadyActed {
    if (_currentUserName == null) return false;
    return widget.leave.prioList.any(
      (item) =>
          item.approverName.toLowerCase() == _currentUserName!.toLowerCase() &&
          item.apstatu != 2, // 2 = pending
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LeaveActionViewModel(),
      child: Consumer<LeaveActionViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              Scaffold(
                backgroundColor: Colors.grey[50],
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  centerTitle: false,
                  title: Text(
                    language.leaveDetail,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEmployeeCard(viewModel),
                      const SizedBox(height: 16),
                      _buildLeaveDetailsCard(),
                      const SizedBox(height: 16),
                      if (widget.leave.file != null &&
                          widget.leave.file!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSupportingDocumentCard(),
                      ],
                      const SizedBox(height: 16),
                      ApprovalWorkflowWidget(
                        approvalList:
                            widget.leave.prioList
                                .map(
                                  (approval) =>
                                      ApprovalItemData.fromCeoApprovalItem(
                                        approval,
                                      ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 200),
                    ],
                  ),
                ),
                floatingActionButton:
                    widget.isPending &&
                            !_isLoadingUser &&
                            !_hasCurrentUserAlreadyActed
                        ? Consumer<LeaveActionViewModel>(
                          builder: (context, viewModel, child) {
                            return SafeArea(
                              child: LeaveActionButtons(
                                leaveId: widget.leave.lreid,
                                approve: language.approve,
                                reject: language.reject,
                                employeeName: widget.leave.requesterName,
                                leaveType: widget.leave.ltyp,
                                numLeaveDays: widget.leave.numLeaveDays,
                                fromDate: widget.leave.fromDate,
                                toDate: widget.leave.toDate,
                                onAction: _handleLeaveAction,
                                viewModel: viewModel,
                                showApproveRemark: true,
                              ),
                            );
                          },
                        )
                        : null,
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
              ),
              if (_isNavigating)
                Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: primary),
                          const SizedBox(height: 16),
                          Text(
                            language.pleaseWait,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleLeaveAction(bool isApprove, String remark, bool success) {
    if (success) {
      setState(() => _isNavigating = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          widget.onActionComplete?.call();
          Navigator.pop(context);
        }
      });
    }
  }

  Widget _buildEmployeeCard(LeaveActionViewModel viewModel) {
    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, primary.withOpacity(0.8)],
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
                          widget.leave.requesterName.isNotEmpty
                              ? widget.leave.requesterName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primary,
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
                                      widget.leave.statu,
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
                          widget.leave.requesterName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${language.staffId}: ${widget.leave.staff_id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            widget.leave.ltyp,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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
                              : FileHelper.getStatusColor(widget.leave.statu))
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
                              : widget.leave.statuText,
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
                    widget.leave.branch,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.work_outline,
                    language.position,
                    widget.leave.position,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.business_outlined,
                    language.department,
                    widget.leave.department,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.email_outlined,
                    language.email,
                    widget.leave.email,
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
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

  Widget _buildLeaveDetailsCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
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
              language.fromDate,
              DateFormat('EEEE, MMMM dd, yyyy').format(widget.leave.fromDate),
              Icons.date_range,
            ),
            _buildDetailRow(
              language.toDate,
              DateFormat('EEEE, MMMM dd, yyyy').format(widget.leave.toDate),
              Icons.date_range,
            ),
            _buildDetailRow(
              language.duration,
              '${widget.leave.numLeaveDays} ${widget.leave.numLeaveDays == 1 ? language.day : language.days}',
              Icons.schedule,
            ),
            _buildDetailRow(
              language.leaveNote,
              widget.leave.leaveNote,
              Icons.note_outlined,
            ),
            _buildDetailRow(
              language.appliedOn,
              DateFormat(
                'MMMM dd, yyyy hh:mm a',
              ).format(widget.leave.requestDate),
              Icons.access_time,
            ),

            if (widget.leave.reason.isNotEmpty) ...[
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
                  widget.leave.reason,
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
      widget.leave.file!,
      accentColor: primary,
    );
  }

  IconData _getStatusIcon() {
    switch (widget.leave.statu.toLowerCase()) {
      case '1':
        return Icons.check_circle;
      case '0':
        return Icons.cancel;
      case '2':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}
