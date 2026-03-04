import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../constants/constant.dart';
import '../../models/ceo_dashboard_model.dart';
import '../../utils/file_helper.dart';
import '../../viewmodels/attendance_adjustment_action_viewmodel.dart';
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
              title: const Text(
                'Attendance Adjustment Detail',
                style: TextStyle(fontWeight: FontWeight.w600),
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
                    const SizedBox(height: 16),
                    _buildSupportingDocumentCard(),
                  ],
                  const SizedBox(height: 100), // Space for floating buttons
                ],
              ),
            ),
            floatingActionButton:
                widget.isPending
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
                          'Staff ID: ${widget.request.staffId}',
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
                              ? 'PROCESSED'
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
                  const Text(
                    'Employee Information',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.location_on_outlined,
                    'Branch',
                    widget.request.branchFullName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.work_outline,
                    'Position',
                    widget.request.positionName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.business_outlined,
                    'Department',
                    widget.request.departmentName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.email_outlined,
                    'Email',
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
              'Adjustment Type',
              widget.request.adjustType,
              Icons.edit_calendar,
            ),
            _buildDetailRow(
              'Adjustment Date',
              DateFormat(
                'EEEE, MMMM dd, yyyy',
              ).format(widget.request.adjustDate),
              Icons.date_range,
            ),
            _buildDetailRow(
              'Requested On',
              DateFormat(
                'MMMM dd, yyyy at hh:mm a',
              ).format(widget.request.requestDate),
              Icons.access_time,
            ),

            if (widget.request.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Reason',
                style: TextStyle(
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
                Icon(Icons.attach_file, color: secondary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Supporting Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Check if the file is an image
            if (_isImageFile(widget.request.documentUrl!)) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.request.documentUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: SpinKitFadingCircle(color: secondary),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[100],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ] else ...[
              // For non-image files, show file icon and details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFileIcon(widget.request.documentUrl!),
                        color: secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFileName(widget.request.documentUrl!),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFileType(widget.request.documentUrl!),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isImageFile(String url) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = url.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  IconData _getFileIcon(String url) {
    final extension = url.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getFileName(String url) {
    return url.split('/').last;
  }

  String _getFileType(String url) {
    final extension = url.split('.').last.toUpperCase();
    return '$extension Document';
  }
}
