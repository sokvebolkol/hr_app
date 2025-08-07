import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constants/constant.dart';
import '../../../models/leave_history_model.dart';
import '../../../viewmodels/update_leave_viewmodel.dart';

class UpdateLeaveScreen extends StatefulWidget {
  final LeaveHistoryModel leaveRequest;

  const UpdateLeaveScreen({super.key, required this.leaveRequest});

  @override
  State<UpdateLeaveScreen> createState() => _UpdateLeaveScreenState();
}

class _UpdateLeaveScreenState extends State<UpdateLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  late UpdateLeaveViewModel _viewModel;

  String? leaveType;
  DateTimeRange? leaveDateRange;
  String leaveFor = 'Full Day';
  String halfDaySession = 'Morning';
  String reason = '';
  String? approver;
  String? documentSupport;
  XFile? documentPhoto;

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
  ]; // Replace with backend data

  @override
  void initState() {
    super.initState();
    _viewModel = UpdateLeaveViewModel(widget.leaveRequest);
    _initializeFormData();
  }

  void _initializeFormData() {
    // Initialize form with existing leave request data
    final leave = widget.leaveRequest;

    leaveType = leave.ltyp;
    reason = leave.reason;

    // Parse date range from leave request
    try {
      final startDate = DateTime.parse(leave.frdat);
      final endDate = DateTime.parse(leave.todat);
      leaveDateRange = DateTimeRange(start: startDate, end: endDate);
    } catch (e) {
      // Handle date parsing error
      print('Error parsing dates: $e');
    }

    // Set leave for based on number of leave days
    final numDays = double.tryParse(leave.numleav) ?? 0;
    if (numDays == 0.5) {
      leaveFor = 'Half Day';
    } else {
      leaveFor = 'Full Day';
    }

    // Set default approver (first in list for now)
    if (approvers.isNotEmpty) {
      approver = approvers.first;
    }

    // Set default document support
    documentSupport = 'None';
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  double get totalLeaveDays {
    if (leaveDateRange != null) {
      final days =
          leaveDateRange!.end.difference(leaveDateRange!.start).inDays + 1;
      if (leaveFor == 'Half Day') {
        if (days == 1) return 0.5;
        if (days == 2) return 1.0; // 0.5 + 0.5
        return (days - 2) + 0.5 + 0.5; // first and last day half, rest full
      }
      return days.toDouble();
    }
    return 0;
  }

  String get leaveDateLabel {
    if (leaveDateRange == null) return 'Select date range';
    final start = DateFormat('yyyy-MM-dd').format(leaveDateRange!.start);
    final end = DateFormat('yyyy-MM-dd').format(leaveDateRange!.end);
    return start == end ? start : '$start to $end';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
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
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final horizontalPadding = isWide ? 80.0 : 18.0;
              final cardPadding = isWide ? 32.0 : 18.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 18,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildHeaderCard(cardPadding, isWide),
                      const SizedBox(height: 16),
                      _buildLeaveTypeCard(cardPadding),
                      const SizedBox(height: 16),
                      _buildDateRangeCard(cardPadding),
                      const SizedBox(height: 16),
                      _buildLeaveForCard(cardPadding),
                      const SizedBox(height: 16),
                      _buildReasonCard(cardPadding),
                      const SizedBox(height: 16),
                      _buildApproverCard(cardPadding),
                      const SizedBox(height: 16),
                      _buildDocumentSupportCard(cardPadding),
                      const SizedBox(height: 24),
                      Consumer<UpdateLeaveViewModel>(
                        builder: (context, viewModel, child) {
                          return _buildUpdateButton(viewModel);
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(double cardPadding, bool isWide) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: cardPadding,
          vertical: cardPadding + 6,
        ),
        child: Column(
          children: [
            Icon(Icons.edit, color: primary, size: isWide ? 64 : 48),
            const SizedBox(height: 12),
            Text(
              'Update Leave Request',
              style: TextStyle(
                fontSize: isWide ? 26 : 22,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Request ID: ${widget.leaveRequest.lreid}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can only update pending leave requests. Changes will require re-approval.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
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

  Widget _buildLeaveTypeCard(double cardPadding) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category_outlined, color: primary, size: 20),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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
        ),
      ),
    );
  }

  Widget _buildDateRangeCard(double cardPadding) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: primary, size: 20),
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
                    Icon(Icons.date_range, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      leaveDateLabel,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            leaveDateRange == null
                                ? Colors.grey[600]
                                : Colors.black87,
                      ),
                    ),
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
        ),
      ),
    );
  }

  Widget _buildLeaveForCard(double cardPadding) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_outlined, color: primary, size: 20),
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
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => leaveFor = option),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  leaveFor == option
                                      ? primary
                                      : Colors.grey[100],
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
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap:
                                () => setState(() => halfDaySession = option),
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
        ),
      ),
    );
  }

  Widget _buildReasonCard(double cardPadding) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, color: primary, size: 20),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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
        ),
      ),
    );
  }

  Widget _buildApproverCard(double cardPadding) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Approver',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: approver,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              hint: const Text('Select approver'),
              items:
                  approvers.map((name) {
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
              onChanged: (value) => setState(() => approver = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an approver';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSupportCard(double cardPadding) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_file_outlined, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Supporting Document',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: documentSupport,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              hint: const Text('Select document type'),
              items:
                  documentSupportOptions.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
              onChanged: (value) => setState(() => documentSupport = value),
            ),
            if (documentSupport != null && documentSupport != 'None') ...[
              const SizedBox(height: 16),
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
                    child: Image.file(
                      File(documentPhoto!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateButton(UpdateLeaveViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
    final initialRange =
        leaveDateRange ??
        DateTimeRange(start: now, end: now.add(const Duration(days: 1)));

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

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          documentPhoto = pickedFile;
        });
      }
    }
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
      'approver': approver,
      'document_support': documentSupport,
      'total_days': totalLeaveDays.toString(),
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
        Navigator.pop(context, true); // Return true to indicate success
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
