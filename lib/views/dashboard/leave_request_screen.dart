import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/constant.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String? leaveType;
  DateTimeRange? leaveDateRange;
  String leaveFor = 'Full Day';
  String halfDaySession = 'Morning';
  String reason = '';
  String? approver;
  String? documentSupport;
  XFile? documentPhoto;
  List<String> approvers = [
    'Mr. John Doe',
    'Ms. Jane Smith',
  ]; // Replace with backend data

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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Request Leave"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final horizontalPadding = isWide ? 80.0 : 18.0;
            final cardPadding = isWide ? 32.0 : 18.0;
            final fontSizeTitle = isWide ? 26.0 : 22.0;
            final fontSizeLabel = isWide ? 18.0 : 15.0;
            final imageSize = isWide ? 80.0 : 48.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, vertical: 18),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: cardPadding,
                          vertical: cardPadding + 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Icon(
                                Icons.beach_access,
                                color: primary,
                                size: isWide ? 64 : 48,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                "Leave Application",
                                style: TextStyle(
                                  fontSize: fontSizeTitle,
                                  fontWeight: FontWeight.bold,
                                  color: secondary,
                                ),
                              ),
                            ),
                            SizedBox(height: isWide ? 32 : 24),

                            // Leave Type
                            Row(
                              children: [
                                Icon(Icons.category, color: primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Leave Type",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeLabel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: leaveType,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: isWide ? 16 : 10,
                                ),
                              ),
                              items: [
                                'Annual Leave',
                                'Sick Leave',
                                'Maternity Leave',
                                'Unpaid Leave',
                                'Special Leave',
                              ]
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => leaveType = val),
                              validator: (val) =>
                                  val == null ? 'Please select leave type' : null,
                            ),
                            SizedBox(height: isWide ? 24 : 18),

                            // Leave Date Range Picker
                            Row(
                              children: [
                                Icon(Icons.date_range, color: primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Leave Date",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeLabel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime.now().subtract(
                                      const Duration(days: 365)),
                                  lastDate: DateTime.now().add(
                                      const Duration(days: 365)),
                                  initialDateRange: leaveDateRange,
                                );
                                if (picked != null)
                                  setState(() => leaveDateRange = picked);
                              },
                              child: AbsorbPointer(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    hintText: 'Select date range',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    suffixIcon: const Icon(Icons.calendar_today),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: isWide ? 16 : 10,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: leaveDateLabel,
                                  ),
                                  validator: (_) =>
                                      leaveDateRange == null
                                          ? 'Please select leave date'
                                          : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Total Leave Days
                            if (leaveDateRange != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.calculate, color: primary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Total Leave: ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: secondary,
                                        fontSize: fontSizeLabel,
                                      ),
                                    ),
                                    Chip(
                                      backgroundColor: primary.withOpacity(0.1),
                                      label: Text(
                                        "${totalLeaveDays % 1 == 0 ? totalLeaveDays.toInt() : totalLeaveDays} day${totalLeaveDays > 1 ? 's' : ''}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primary,
                                          fontSize: isWide ? 18 : 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Leave For
                            Row(
                              children: [
                                Icon(Icons.timelapse, color: primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Leave For",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeLabel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Full Day'),
                                    value: 'Full Day',
                                    groupValue: leaveFor,
                                    onChanged: (val) =>
                                        setState(() => leaveFor = val!),
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Half Day'),
                                    value: 'Half Day',
                                    groupValue: leaveFor,
                                    onChanged: (val) =>
                                        setState(() => leaveFor = val!),
                                  ),
                                ),
                              ],
                            ),
                            if (leaveFor == 'Half Day') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.wb_sunny, color: primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Leave Note",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: fontSizeLabel),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Morning'),
                                      value: 'Morning',
                                      groupValue: halfDaySession,
                                      onChanged: (val) =>
                                          setState(() => halfDaySession = val!),
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text('Afternoon'),
                                      value: 'Afternoon',
                                      groupValue: halfDaySession,
                                      onChanged: (val) =>
                                          setState(() => halfDaySession = val!),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            SizedBox(height: isWide ? 24 : 18),

                            // Reason
                            Row(
                              children: [
                                Icon(Icons.edit_note, color: primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Reason",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeLabel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Enter your reason",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: isWide ? 16 : 10,
                                ),
                              ),
                              onChanged: (val) => reason = val,
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Please enter reason'
                                  : null,
                            ),
                            SizedBox(height: isWide ? 24 : 18),

                            // Document Support (Conditional)
                            if (leaveType == 'Sick Leave' ||
                                leaveType == 'Maternity Leave' ||
                                leaveType == 'Special Leave') ...[
                              SizedBox(height: isWide ? 24 : 18),
                              Row(
                                children: [
                                  Icon(Icons.attach_file, color: primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Document Support",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: fontSizeLabel),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    icon: const Icon(Icons.visibility),
                                    label: const Text("View Sample"),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Sample Document"),
                                          content: Image.asset(
                                            'assets/sample_document.jpg',
                                            fit: BoxFit.contain,
                                            width: isWide ? 350 : 250,
                                            height: isWide ? 400 : 300,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("Close"),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: documentPhoto == null
                                        ? Text(
                                            "No photo selected",
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontStyle: FontStyle.italic,
                                              fontSize: isWide ? 16 : 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        : Row(
                                            children: [
                                              Image.file(
                                                File(documentPhoto!.path),
                                                width: imageSize,
                                                height: imageSize,
                                                fit: BoxFit.cover,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "Photo selected",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: isWide ? 16 : 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text("Upload Photo"),
                                    onPressed: () async {
                                      showModalBottomSheet(
                                        context: context,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                        ),
                                        builder: (context) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                "Select Photo Source",
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                              ),
                                              const SizedBox(height: 16),
                                              ListTile(
                                                leading: const Icon(Icons.camera_alt, color: Colors.black87),
                                                title: const Text("Camera"),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  final picker = ImagePicker();
                                                  final picked = await picker.pickImage(source: ImageSource.camera);
                                                  if (picked != null) {
                                                    setState(() {
                                                      documentPhoto = picked;
                                                    });
                                                  }
                                                },
                                              ),
                                              ListTile(
                                                leading: const Icon(Icons.photo_library, color: Colors.black87),
                                                title: const Text("Gallery"),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  final picker = ImagePicker();
                                                  final picked = await picker.pickImage(source: ImageSource.gallery);
                                                  if (picked != null) {
                                                    setState(() {
                                                      documentPhoto = picked;
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],

                            // Approvers (Fancy Read-only)
                            Card(
                              color: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: isWide ? 18 : 14,
                                  horizontal: isWide ? 18 : 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.supervisor_account, color: primary),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Approvers",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: isWide ? 19 : 17,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ...approvers.take(2).toList().asMap().entries.map(
                                      (entry) => Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: primary.withOpacity(0.15),
                                                  radius: isWide ? 22 : 18,
                                                  child: const Icon(
                                                    Icons.verified_user,
                                                    color: secondary,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        entry.value,
                                                        style: TextStyle(
                                                          fontSize: isWide ? 18 : 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.black87,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        entry.key == 0 ? 'First Approver' : 'Second Approver',
                                                        style: TextStyle(
                                                          fontSize: isWide ? 15 : 13,
                                                          fontWeight: FontWeight.w400,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isWide ? 32 : 18),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isWide ? 32 : 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isWide ? 20 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(
                            fontSize: isWide ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text("Submit"),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            // TODO: Submit leave request to backend
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Leave request submitted!'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
