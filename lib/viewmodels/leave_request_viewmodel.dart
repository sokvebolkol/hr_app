import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/leave_type_model.dart';
import '../models/approver_model.dart';
import '../repositories/leave_request_repository.dart';

class LeaveRequestViewModel extends ChangeNotifier {
  final LeaveRequestRepository _repository = LeaveRequestRepository();

  // Backend data state
  List<LeaveTypeModel> _leaveTypes = [];
  List<ApproverModel> _approvers = [];
  List<String> _holidays = [];
  String _userId = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Form state
  LeaveTypeModel? _selectedLeaveType;
  DateTimeRange? _leaveDateRange;
  String _leaveFor = 'Full Day';
  String _halfDaySession = 'Morning';
  String _reason = '';
  XFile? _documentPhoto;

  // Submission state
  bool _isSubmitting = false;

  // Getters
  List<LeaveTypeModel> get leaveTypes => _leaveTypes;
  List<ApproverModel> get approvers => _approvers;
  List<String> get holidays => _holidays;
  String get userId => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LeaveTypeModel? get selectedLeaveType => _selectedLeaveType;
  DateTimeRange? get leaveDateRange => _leaveDateRange;
  String get leaveFor => _leaveFor;
  String get halfDaySession => _halfDaySession;
  String get reason => _reason;
  XFile? get documentPhoto => _documentPhoto;
  bool get isSubmitting => _isSubmitting;

  // Computed getters
  List<ApproverModel> get sortedApprovers {
    final sorted = [..._approvers];
    sorted.sort((a, b) => a.approvalLevel.compareTo(b.approvalLevel));
    return sorted;
  }

  double get totalLeaveDays {
    if (_leaveDateRange != null) {
      int workingDays = 0;
      DateTime current = _leaveDateRange!.start;

      while (current.isBefore(
        _leaveDateRange!.end.add(const Duration(days: 1)),
      )) {
        if (current.weekday != DateTime.saturday &&
            current.weekday != DateTime.sunday) {
          final dateString = current.toIso8601String().split('T')[0];
          if (!_holidays.contains(dateString)) {
            workingDays++;
          }
        }
        current = current.add(const Duration(days: 1));
      }

      if (_leaveFor == 'Half Day') {
        if (workingDays == 1) return 0.5;
        if (workingDays == 2) return 1.5;
        return 0.5 + (workingDays - 1);
      }
      return workingDays.toDouble();
    }
    return 0;
  }

  String get leaveDateLabel {
    if (_leaveDateRange == null) return '';
    final start = DateFormat('yyyy-MM-dd').format(_leaveDateRange!.start);
    final end = DateFormat('yyyy-MM-dd').format(_leaveDateRange!.end);
    return start == end ? start : '$start to $end';
  }

  List<Map<String, dynamic>> get formattedApprovers {
    final uniqueApprovers = <String, ApproverModel>{};
    for (var approver in sortedApprovers) {
      uniqueApprovers[approver.approverId.toString()] = approver;
    }
    return uniqueApprovers.values.map((approver) {
      return {
        "eid": approver.approverId.toString(),
        "applev": approver.approvalLevel,
        "prio": approver.approvalLevel,
      };
    }).toList();
  }

  int get leaveForValue => _leaveFor == 'Full Day' ? 1 : 0;

  // Setters
  void setSelectedLeaveType(String? leaid) {
    if (leaid == null) return;
    _selectedLeaveType = _leaveTypes.firstWhere((type) => type.leaid == leaid);
    if (!(_selectedLeaveType?.requiresDocument ?? false)) {
      _documentPhoto = null;
    }
    notifyListeners();
  }

  void setLeaveDateRange(DateTimeRange? range) {
    _leaveDateRange = range;
    notifyListeners();
  }

  void setLeaveFor(String value) {
    _leaveFor = value;
    notifyListeners();
  }

  void setHalfDaySession(String value) {
    _halfDaySession = value;
    notifyListeners();
  }

  void setReason(String value) {
    _reason = value;
    // No notifyListeners — reason changes don't affect any computed UI state
  }

  void setDocumentPhoto(XFile? photo) {
    _documentPhoto = photo;
    notifyListeners();
  }

  // Fetch initial data from API
  Future<void> fetchLeaveRequestData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getLeaveRequestData();
      _leaveTypes = data.leaveTypes;
      _approvers = data.approvers;
      _holidays = data.holidays;
      _userId = data.userId;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit the leave request; throws on network/server error
  Future<LeaveRequestResponse> submitLeaveRequest() async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final fromDate = DateFormat('yyyy-MM-dd').format(_leaveDateRange!.start);
      final toDate = DateFormat('yyyy-MM-dd').format(_leaveDateRange!.end);

      File? fileToUpload;
      if (_documentPhoto != null) {
        fileToUpload = File(_documentPhoto!.path);
      }

      final response = await _repository.submitLeaveRequest(
        leaveType: _selectedLeaveType!.leaid,
        fromDate: fromDate,
        toDate: toDate,
        reason: _reason.trim(),
        leaveFor: leaveForValue,
        halfDaySession: _halfDaySession,
        totalLeave: totalLeaveDays,
        approvers: formattedApprovers,
        file: fileToUpload,
      );

      _isSubmitting = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  // Validation helpers — delegate to repository
  bool isValidImageFile(File file) => _repository.isValidImageFile(file);
  Future<bool> isValidFileSize(File file) => _repository.isValidFileSize(file);
}
