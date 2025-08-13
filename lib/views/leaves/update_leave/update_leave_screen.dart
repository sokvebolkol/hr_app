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
  List<String> documentSupportOptions = [
    'None',
    'Medical Certificate',
    'Marriage Certificate',
    'Death Certificate',
    'Birth Certificate',
    'Other',
  ];

  List<String> approvers = [
    'Mr. John Doe',
    'Ms. Jane Smith',
    'Dr. Michael Brown',
  ];

  @override
  void initState() {
    super.initState();
    _viewModel = UpdateLeaveViewModel(widget.leaveRequest);
    _initializeFormData();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

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
      final startDate = FileHelper.formatDate(leave.fromDate);
      final endDate = FileHelper.formatDate(leave.toDate);
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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCurrentRequestCard(),
                    const SizedBox(height: 20),
                    _buildUpdateFormCard(),
                    const SizedBox(height: 20),
                    Consumer<UpdateLeaveViewModel>(
                      builder: (context, viewModel, child) {
                        return _buildUpdateButton(viewModel);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
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

  Widget _buildCurrentRequestCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FileHelper.getStatusColor(widget.leaveRequest.statu),
            FileHelper.getStatusColor(
              widget.leaveRequest.statu,
            ).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit_document,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Updating Request',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.leaveRequest.statusText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changes will require re-approval from your managers.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
