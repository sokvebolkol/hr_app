import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/constant.dart';
import '../../../models/leave_history_model.dart';
import '../../../utils/file_helper.dart';
import '../../../viewmodels/update_leave_viewmodel.dart';
import '../../../widgets/compact_detail_row.dart';
import '../../../widgets/compact_status_card.dart';
import '../../../widgets/action_buttons_card.dart';

class UpdateLeaveScreen extends StatefulWidget {
  final LeaveHistoryModel leaveRequest;

  const UpdateLeaveScreen({super.key, required this.leaveRequest});

  @override
  State<UpdateLeaveScreen> createState() => _UpdateLeaveScreenState();
}

class _UpdateLeaveScreenState extends State<UpdateLeaveScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late UpdateLeaveViewModel _viewModel;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  String? leaveType;
  DateTimeRange? leaveDateRange;
  String leaveFor = 'Full Day';
  String halfDaySession = 'Morning';
  String reason = '';
  String? approver;
  String? documentSupport;
  XFile? documentPhoto;
  bool _hasExistingDocument = false;
  bool _removeExistingDocument = false;

  List<String> leaveTypes = [
    'Annual Leave',
    'Sick Leave',
    'Personal Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Emergency Leave',
  ];

  List<String> leaveForOptions = ['Full Day', 'Half Day'];
  List<String> halfDayOptions = ['Morning', 'Afternoon'];

  List<String> approvers = [
    'Mr. John Doe',
    'Ms. Jane Smith',
    'Dr. Michael Brown',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = UpdateLeaveViewModel(widget.leaveRequest);
    _setupAnimations();
    _initializeFormData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _tabController = TabController(length: 3, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  void _initializeFormData() {
    final leave = widget.leaveRequest;

    leaveType = leave.ltyp;
    reason = leave.reason;

    // Check if leave has existing document
    _hasExistingDocument =
        leave.documentUrl != null && leave.documentUrl!.isNotEmpty;

    // Parse date range from leave request
    try {
      final startDate = leave.fromDate;
      final endDate = leave.toDate;
      leaveDateRange = DateTimeRange(start: startDate, end: endDate);
    } catch (e) {
      print('Error parsing dates: $e');
    }

    // Set leave for based on number of leave days
    final numDays = double.tryParse(leave.numleav) ?? 0;
    if (numDays == 0.5) {
      leaveFor = 'Half Day';
    } else {
      leaveFor = 'Full Day';
    }

    // Set default approver
    if (approvers.isNotEmpty) {
      approver = approvers.first;
    }

    // Set document support based on existing document
    documentSupport = _hasExistingDocument ? 'Other' : 'None';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  double get totalLeaveDays {
    if (leaveDateRange != null) {
      final days =
          leaveDateRange!.end.difference(leaveDateRange!.start).inDays + 1;
      if (leaveFor == 'Half Day') {
        if (days == 1) return 0.5;
        return days * 0.5;
      }
      return days.toDouble();
    }
    return 0;
  }

  String get leaveDateLabel {
    if (leaveDateRange == null) return 'Select date range';
    final start = DateFormat('MMM dd, yyyy').format(leaveDateRange!.start);
    final end = DateFormat('MMM dd, yyyy').format(leaveDateRange!.end);
    return start == end ? start : '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Tab Bar
              _buildTabBar(),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCurrentDetailsTab(),
                    _buildUpdateFormTab(),
                    _buildPreviewTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        "Update Leave Request",
        style: TextStyle(
          fontSize: 20,
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
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: _showUpdateInfo,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: primary,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Current'),
          Tab(icon: Icon(Icons.edit, size: 20), text: 'Update'),
          Tab(icon: Icon(Icons.preview, size: 20), text: 'Preview'),
        ],
      ),
    );
  }

  Widget _buildCurrentDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Request Status Card
          CompactStatusCard(
            status: widget.leaveRequest.statu,
            statusText: widget.leaveRequest.statusText,
            id: widget.leaveRequest.lreid,
            duration:
                '${widget.leaveRequest.numleav} day${double.parse(widget.leaveRequest.numleav) > 1 ? 's' : ''}',
            durationType:
                widget.leaveRequest.isFullDay ? 'Full Day' : 'Half Day',
            hasDocument: _hasExistingDocument,
            customTitle: 'Current Request',
          ),

          const SizedBox(height: 20),

          // Current Details Card
          _buildCurrentDetailsCard(),

          const SizedBox(height: 20),

          // Current Document Card (if exists)
          if (_hasExistingDocument) _buildCurrentDocumentCard(),

          const SizedBox(height: 20),

          // Update Info Card
          _buildUpdateInfoCard(),
        ],
      ),
    );
  }

  Widget _buildCurrentDetailsCard() {
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
                Icon(Icons.info_outline, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Current Leave Details',
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
                        value: FileHelper.formatDate(
                          widget.leaveRequest.toDate,
                        ),
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
                          'Current Reason',
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
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

  Widget _buildCurrentDocumentCard() {
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
                  'Current Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.leaveRequest.documentUrl != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.leaveRequest.documentUrl!,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
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
                                'Failed to load document',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Update Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Updated requests require re-approval from all managers',
            ),
            const SizedBox(height: 4),
            const Text('• All approvers will be notified of changes'),
            const SizedBox(height: 4),
            const Text('• Original request history is preserved'),
            const SizedBox(height: 4),
            const Text('• Status will reset to "Pending"'),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateFormTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUpdateFormCard(),
            const SizedBox(height: 20),

            // Action Buttons
            Consumer<UpdateLeaveViewModel>(
              builder: (context, viewModel, child) {
                return ActionButtonsCard(
                  buttons: [
                    ActionButtonData(
                      label: 'Preview Changes',
                      icon: Icons.preview,
                      onPressed: () => _tabController.animateTo(2),
                      backgroundColor: Colors.blue,
                    ),
                    ActionButtonData(
                      label: 'Update Request',
                      icon: Icons.save,
                      onPressed: _updateLeave,
                      backgroundColor: primary,
                      isLoading: viewModel.isLoading,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Preview Status Card
          CompactStatusCard(
            status: '2', // Pending status
            statusText: 'Pending (After Update)',
            id: widget.leaveRequest.lreid,
            duration: '${totalLeaveDays} day${totalLeaveDays != 1 ? 's' : ''}',
            durationType: leaveFor,
            hasDocument:
                documentPhoto != null ||
                (_hasExistingDocument && !_removeExistingDocument),
            customTitle: 'Updated Request Preview',
          ),

          const SizedBox(height: 20),

          // Preview Details Card
          _buildPreviewDetailsCard(),

          const SizedBox(height: 20),

          // Changes Summary Card
          _buildChangesSummaryCard(),

          const SizedBox(height: 20),

          // Final Action Buttons
          Consumer<UpdateLeaveViewModel>(
            builder: (context, viewModel, child) {
              return ActionButtonsCard(
                layout: ButtonLayout.row,
                buttons: [
                  ActionButtonData(
                    label: 'Back to Edit',
                    icon: Icons.edit,
                    onPressed: () => _tabController.animateTo(1),
                    backgroundColor: Colors.grey,
                  ),
                  ActionButtonData(
                    label: 'Submit Update',
                    icon: Icons.send,
                    onPressed: _updateLeave,
                    backgroundColor: Colors.green,
                    isLoading: viewModel.isLoading,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewDetailsCard() {
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
                Icon(Icons.preview, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Updated Details Preview',
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
                        label: 'Leave Type',
                        value: leaveType ?? 'Not selected',
                        icon: Icons.category,
                      ),
                      const SizedBox(height: 12),
                      CompactDetailRow(
                        label: 'From Date',
                        value:
                            leaveDateRange != null
                                ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(leaveDateRange!.start)
                                : 'Not selected',
                        icon: Icons.date_range,
                      ),
                      const SizedBox(height: 12),
                      CompactDetailRow(
                        label: 'Duration Type',
                        value: leaveFor,
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
                        label: 'Total Days',
                        value:
                            '${totalLeaveDays} day${totalLeaveDays != 1 ? 's' : ''}',
                        icon: Icons.access_time,
                      ),
                      const SizedBox(height: 12),
                      CompactDetailRow(
                        label: 'To Date',
                        value:
                            leaveDateRange != null
                                ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(leaveDateRange!.end)
                                : 'Not selected',
                        icon: Icons.date_range,
                      ),
                      if (leaveFor == 'Half Day') ...[
                        const SizedBox(height: 12),
                        CompactDetailRow(
                          label: 'Session',
                          value: halfDaySession,
                          icon: Icons.schedule_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (reason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Updated Reason',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
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

  Widget _buildChangesSummaryCard() {
    final changes = <String>[];

    if (leaveType != widget.leaveRequest.ltyp) {
      changes.add('Leave type: ${widget.leaveRequest.ltyp} → $leaveType');
    }

    if (leaveDateRange != null) {
      final currentStart = DateFormat(
        'MMM dd, yyyy',
      ).format(widget.leaveRequest.fromDate);
      final currentEnd = DateFormat(
        'MMM dd, yyyy',
      ).format(widget.leaveRequest.toDate);
      final newStart = DateFormat('MMM dd, yyyy').format(leaveDateRange!.start);
      final newEnd = DateFormat('MMM dd, yyyy').format(leaveDateRange!.end);

      if (currentStart != newStart || currentEnd != newEnd) {
        changes.add('Dates: $currentStart - $currentEnd → $newStart - $newEnd');
      }
    }

    if (reason != widget.leaveRequest.reason) {
      changes.add('Reason updated');
    }

    if (_removeExistingDocument) {
      changes.add('Document removed');
    }

    if (documentPhoto != null) {
      changes.add('New document attached');
    }

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
                Icon(Icons.compare_arrows, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Changes Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (changes.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    const Text('No changes detected'),
                  ],
                ),
              ),
            ] else ...[
              ...changes.map(
                (change) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.arrow_right,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          change,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateFormCard() {
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
                Icon(Icons.edit, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Update Leave Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Leave Type
            _buildLeaveTypeSection(),
            const SizedBox(height: 20),

            // Date Range
            _buildDateRangeSection(),
            const SizedBox(height: 20),

            // Leave Duration
            _buildLeaveDurationSection(),
            const SizedBox(height: 20),

            // Reason
            _buildReasonSection(),
            const SizedBox(height: 20),

            // Document Support
            if (_shouldShowDocumentSection()) _buildDocumentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.category_outlined, color: primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Leave Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: leaveType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          hint: const Text('Select leave type'),
          items:
              leaveTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
          onChanged: (value) => setState(() => leaveType = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a leave type';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, color: primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Leave Dates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    leaveDateLabel,
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          leaveDateRange == null
                              ? Colors.grey[600]
                              : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        if (leaveDateRange != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Total: ${totalLeaveDays} day${totalLeaveDays != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLeaveDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_outlined, color: primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Leave Duration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children:
              leaveForOptions.map((option) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: option == leaveForOptions.last ? 0 : 8,
                    ),
                    child: InkWell(
                      onTap: () => setState(() => leaveFor = option),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              leaveFor == option ? primary : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                leaveFor == option
                                    ? primary
                                    : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                leaveFor == option
                                    ? Colors.white
                                    : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
        if (leaveFor == 'Half Day') ...[
          const SizedBox(height: 16),
          const Text(
            'Half Day Session',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children:
                halfDayOptions.map((option) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option == halfDayOptions.last ? 0 : 8,
                      ),
                      child: InkWell(
                        onTap: () => setState(() => halfDaySession = option),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                halfDaySession == option
                                    ? primary
                                    : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  halfDaySession == option
                                      ? primary
                                      : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  halfDaySession == option
                                      ? Colors.white
                                      : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.description_outlined, color: primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Reason for Leave',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: reason,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter the reason for your leave...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) => reason = value,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a reason for your leave';
            }
            if (value.trim().length < 10) {
              return 'Please provide a more detailed reason (at least 10 characters)';
            }
            return null;
          },
        ),
      ],
    );
  }

  bool _shouldShowDocumentSection() {
    return [
      'Sick Leave',
      'Medical Leave',
      'Maternity Leave',
      'Paternity Leave',
    ].contains(leaveType);
  }

  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_file_outlined, color: primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Supporting Document',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Existing document info
        if (_hasExistingDocument && !_removeExistingDocument) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.attachment, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current document attached',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () => setState(() => _removeExistingDocument = true),
                      child: Text(
                        'Remove',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    ),
                  ],
                ),
                if (widget.leaveRequest.documentUrl != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.leaveRequest.documentUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey[400],
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Upload new document section
        if (_removeExistingDocument || !_hasExistingDocument) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDocument,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(
                    documentPhoto == null ? 'Take Photo' : 'Change Photo',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDocumentFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('From Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (documentPhoto != null) ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(documentPhoto!.path), fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildUpdateButton(UpdateLeaveViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: ElevatedButton(
        onPressed: viewModel.isLoading ? null : _updateLeave,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child:
            viewModel.isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'Update Leave Request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final initialRange = leaveDateRange ?? DateTimeRange(start: now, end: now);

    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange != null) {
      setState(() {
        leaveDateRange = selectedRange;
      });
    }
  }

  Future<void> _pickDocument() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        documentPhoto = pickedFile;
      });
    }
  }

  Future<void> _pickDocumentFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        documentPhoto = pickedFile;
      });
    }
  }

  void _showUpdateInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text('Update Information'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Only pending requests can be updated'),
                SizedBox(height: 8),
                Text('• Updated requests require re-approval'),
                SizedBox(height: 8),
                Text('• All approvers will be notified of changes'),
                SizedBox(height: 8),
                Text('• Original request history is preserved'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateLeave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (leaveDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select leave dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare update data
    final updateData = {
      'leave_type': leaveType,
      'from_date': DateFormat('yyyy-MM-dd').format(leaveDateRange!.start),
      'to_date': DateFormat('yyyy-MM-dd').format(leaveDateRange!.end),
      'leave_for': leaveFor,
      'half_day_session': halfDaySession,
      'reason': reason.trim(),
      'total_days': totalLeaveDays.toString(),
      'remove_existing_document': _removeExistingDocument,
    };

    try {
      final result = await _viewModel.updateLeave(updateData, documentPhoto);

      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leave request updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _viewModel.errorMessage ?? 'Failed to update leave request',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
