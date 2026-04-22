import 'package:flutter/material.dart';
import '../../constants/constant.dart';
import '../../localization/language.dart';
import '../../localization/language_logic.dart';
import '../../models/adjustment_request_model.dart';
import '../../repositories/attendance_adjustment_action_repository.dart';
import '../../utils/file_helper.dart';
import '../../widgets/action_buttons_card.dart';
import '../../widgets/approvalworkflowwidget.dart';
import '../../widgets/compact_detail_row.dart';
import '../../widgets/compact_follow_up_button.dart';
import '../../widgets/compact_status_card.dart';

class MyAttendanceAdjustmentRequestScreen extends StatefulWidget {
  final AdjustmentRequestModel adjustmentRequest;

  const MyAttendanceAdjustmentRequestScreen({
    super.key,
    required this.adjustmentRequest,
  });

  @override
  State<MyAttendanceAdjustmentRequestScreen> createState() =>
      _MyAttendanceAdjustmentRequestScreenState();
}

class _MyAttendanceAdjustmentRequestScreenState
    extends State<MyAttendanceAdjustmentRequestScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AttendanceAdjustmentActionRepository _repository =
      AttendanceAdjustmentActionRepository();

  Language language = Language();
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
    _initializeLanguage();
  }

  void _viewDocumentFullScreen() {
    if (widget.adjustmentRequest.documentUrl == null ||
        widget.adjustmentRequest.documentUrl!.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => _FullScreenDocumentViewer(
              imageUrl: widget.adjustmentRequest.documentUrl!,
              title: language.documentSupport,
              language: language,
            ),
      ),
    );
  }

  void _showFollowUpDialog(AdjustmentApprover approver) {
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
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.message,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        language.followUp,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        maxLines: 3,
                        enabled: !isSending,
                        decoration: InputDecoration(
                          hintText: language.enterMessageOptional,
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
                      child: Text(language.cancel),
                    ),
                    ElevatedButton(
                      onPressed:
                          isSending
                              ? null
                              : () async {
                                setDialogState(() => isSending = true);
                                try {
                                  final success = await _repository
                                      .sendAttendanceFollowUp(
                                        widget.adjustmentRequest.id.toString(),
                                        approver.approverId,
                                        messageController.text.trim(),
                                      );

                                  if (!mounted) return;
                                  Navigator.pop(context);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Follow-up sent to ${approver.approverName}'
                                            : 'Failed to send follow-up. Please try again.',
                                      ),
                                      backgroundColor:
                                          success ? Colors.green : Colors.red,
                                    ),
                                  );
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
                              },
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
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
                              : Text(
                                language.send,
                                style: const TextStyle(color: Colors.white),
                              ),
                    ),
                  ],
                ),
          ),
    );
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  Future<void> _handleCancelRequest(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    try {
      setDialogState(() {
        _isCancelling = true;
      });

      final success = await _repository.cancelAttendanceAdjustmentRequest(
        widget.adjustmentRequest.id,
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

        _showSnackBar(
          'Attendance adjustment request cancelled successfully',
          Colors.green,
        );
      } else {
        _showSnackBar(
          'Failed to cancel attendance adjustment request. Please try again.',
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
                  title: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(language.cancelRequest),
                    ],
                  ),
                  content: Text(language.areYouSureToCancel),
                  actions: [
                    TextButton(
                      onPressed:
                          _isCancelling
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                      child: Text(language.no),
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
                              : Text(
                                language.yesCancelRequest,
                                style: const TextStyle(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          language.attendanceRequest,
          style: const TextStyle(
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
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCompactStatusCard(),
                const SizedBox(height: 16),
                _buildDetailsCard(),
                const SizedBox(height: 16),
                if (_hasDocumentSupport()) _buildDocumentSupportCard(),
                if (_hasDocumentSupport()) const SizedBox(height: 16),
                _buildApprovalWorkflowSection(),
                const SizedBox(height: 16),
                if (widget.adjustmentRequest.isAttendanceCanCancel)
                  _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusCard() {
    return CompactStatusCard(
      status: widget.adjustmentRequest.status.toString(),
      statusText: widget.adjustmentRequest.statusText,
      id: widget.adjustmentRequest.id.toString(),
      duration: widget.adjustmentRequest.adjustType,
      durationType: '',
      hasDocument: false,
    );
  }

  Widget _buildDetailsCard() {
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
      child: _buildDetailsSection(),
    );
  }

  Widget _buildDetailsSection() {
    DateTime adjustDate;
    try {
      adjustDate = DateTime.parse(widget.adjustmentRequest.adjustDateTime);
    } catch (e) {
      adjustDate = DateTime.now();
    }

    DateTime createdDate;
    try {
      createdDate = DateTime.parse(widget.adjustmentRequest.createdAt);
    } catch (e) {
      createdDate = DateTime.now();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                language.adjustmentInformation,
                style: const TextStyle(
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
                      label: language.staffId,
                      value: widget.adjustmentRequest.staffId,
                      icon: Icons.badge,
                    ),
                    const SizedBox(height: 12),
                    CompactDetailRow(
                      label: language.checkIn,
                      value: FileHelper().formatTime(
                        widget.adjustmentRequest.checkInTime,
                      ),
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 12),
                    CompactDetailRow(
                      label: language.applied,
                      value: FileHelper.formatDate(createdDate),
                      icon: Icons.schedule,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    CompactDetailRow(
                      label: language.employee,
                      value: widget.adjustmentRequest.requesterName,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    CompactDetailRow(
                      label: language.checkOut,
                      value: FileHelper().formatTime(
                        widget.adjustmentRequest.checkOutTime,
                      ),
                      icon: Icons.logout,
                    ),
                    const SizedBox(height: 12),
                    CompactDetailRow(
                      label: language.adjustDateTime,
                      value: FileHelper.formatDate(adjustDate),
                      icon: Icons.access_time,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.adjustmentRequest.reason.isNotEmpty) ...[
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
                      Icon(Icons.comment, size: 16, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        language.reason,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.adjustmentRequest.reason,
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
    );
  }

  bool _hasDocumentSupport() {
    return widget.adjustmentRequest.hasDocument == true;
  }

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
                Text(
                  language.documentSupport,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (widget.adjustmentRequest.documentUrl != null &&
                    widget.adjustmentRequest.documentUrl!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.blue),
                    onPressed: () => _viewDocumentFullScreen(),
                    tooltip: language.viewFullScreen,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.adjustmentRequest.documentUrl != null &&
                widget.adjustmentRequest.documentUrl!.isNotEmpty)
              _buildDocumentImage()
            else
              _buildNoDocumentPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentImage() {
    return GestureDetector(
      onTap: () => _viewDocumentFullScreen(),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.adjustmentRequest.documentUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
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
                        Text(language.loadingDocument),
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
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.failedToLoadDocument,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Tap to view',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return ActionButtonsCard(
      layout: ButtonLayout.row,
      spacing: 16,
      buttons: [
        ActionButtonData(
          label: language.cancelRequest,
          icon: Icons.cancel_outlined,
          onPressed: _showCancelConfirmation,
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          isLoading: _isCancelling,
        ),
      ],
    );
  }

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
            language.documentExpected,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This adjustment request requires supporting documents, but none were uploaded or document failed to load',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalWorkflowSection() {
    return ApprovalWorkflowWidget(
      title: language.userApprovers,
      approvalList:
          widget.adjustmentRequest.approverList
              .map(
                (approver) => ApprovalItemData(
                  approverName: approver.approverName,
                  priority: approver.priority,
                  roleText: approver.priorityText,
                  status: approver.approvalStatus,
                  statusText: approver.approvalStatusText,
                  remark: approver.remark,
                ),
              )
              .toList(),
      customApprovalBuilder:
          (approval, isLast) => _buildCustomApprovalStep(approval, isLast),
    );
  }

  Widget _buildCustomApprovalStep(ApprovalItemData approval, bool isLast) {
    final originalApprover = widget.adjustmentRequest.approverList.firstWhere(
      (a) =>
          a.approverName == approval.approverName &&
          a.priority == approval.priority,
    );

    Color statusColor = _getApprovalStatusColor(approval.status);
    IconData statusIcon = _getApprovalStatusIcon(approval.status);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      if (originalApprover.isPending &&
                          widget.adjustmentRequest.isPending)
                        CompactFollowUpButton(
                          text: language.followUp,
                          onTap: () => _showFollowUpDialog(originalApprover),
                        )
                      else
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
      case 1:
        return Colors.green;
      case 0:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getApprovalStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.check_circle;
      case 0:
        return Icons.cancel;
      case 2:
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}

class _FullScreenDocumentViewer extends StatefulWidget {
  final String imageUrl;
  final String title;
  final Language language;

  const _FullScreenDocumentViewer({
    required this.imageUrl,
    required this.title,
    required this.language,
  });

  @override
  State<_FullScreenDocumentViewer> createState() =>
      _FullScreenDocumentViewerState();
}

class _FullScreenDocumentViewerState extends State<_FullScreenDocumentViewer> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value =
          Matrix4.identity()
            ..translate(-position.dx * 2, -position.dy * 2)
            ..scale(3.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.language.loadingDocument,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.language.failedToLoadDocument,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Text(
          'Pinch to zoom • Double tap to zoom in/out',
          style: TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
