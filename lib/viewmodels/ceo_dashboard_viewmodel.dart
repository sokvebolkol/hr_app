import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ceo_dashboard_model.dart';
import '../repositories/ceo_dashboard_repository.dart';

class CeoDashboardViewModel extends ChangeNotifier {
  final CeoDashboardRepository _repository = CeoDashboardRepository();

  // State variables
  AttendanceSummary? _attendanceSummary;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedMonth;

  // Getters
  AttendanceSummary? get attendanceSummary => _attendanceSummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedMonth => _selectedMonth;

  // Quick stats getters
  int get totalStaff => _attendanceSummary?.totalStaff ?? 0;
  int get presentCount => _attendanceSummary?.presentCount ?? 0;
  int get lateCount => _attendanceSummary?.lateCount ?? 0;
  int get absentCount => _attendanceSummary?.absentCount ?? 0;
  int get onLeaveCount => _attendanceSummary?.todayStaffLeaves ?? 0;
  int get pendingLeavesCount => _attendanceSummary?.pendingLeavesCount ?? 0;
  int get approvedLeavesCount => _attendanceSummary?.approvedLeavesCount ?? 0;
  double get attendanceRate => _attendanceSummary?.attendanceRate ?? 0;

  List<LeaveRequest> get pendingLeaves =>
      _attendanceSummary?.leaveNeedToApprove ?? [];
  List<LeaveRequest> get approvedLeaves =>
      _attendanceSummary?.approvedLeaves ?? [];

  // Get display text for selected month
  String get selectedMonthDisplay {
    if (_selectedMonth == null) {
      return DateFormat('MMMM yyyy').format(DateTime.now());
    }
    try {
      final date = DateTime.parse('$_selectedMonth-01');
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return 'All Time';
    }
  }

  // Initialize
  void initialize() {
    // Set current month as default
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
    loadAttendanceSummary();
  }

  // Load attendance summary
  Future<void> loadAttendanceSummary() async {
    try {
      _setLoading(true);
      _setError(null);

      print('Loading CEO dashboard attendance summary...');

      final response = await _repository.getAttendanceSummary(
        month: _selectedMonth,
      );

      if (response.success) {
        _attendanceSummary = response.data.summary;
        print('Successfully loaded attendance summary');
        print(
          'Present: $presentCount, Late: $lateCount, Absent: $absentCount, On Leave: $onLeaveCount',
        );
        print(
          'Pending leaves: ${pendingLeaves.length}, Approved leaves: ${approvedLeaves.length}',
        );
      } else {
        throw Exception('API returned success: false');
      }

      _setLoading(false);
    } catch (e) {
      print('Error in loadAttendanceSummary: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
    }
  }

  // Set selected month and refresh data
  Future<void> setSelectedMonth(String? month) async {
    if (_selectedMonth != month) {
      _selectedMonth = month;
      notifyListeners();
      await loadAttendanceSummary();
    }
  }

  // Clear month filter
  Future<void> clearMonthFilter() async {
    await setSelectedMonth(null);
  }

  // Refresh data
  Future<void> refresh() async {
    await loadAttendanceSummary();
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get attendance stats for charts/displays
  Map<String, int> getAttendanceStats() {
    return {
      'Present': presentCount,
      'Late': lateCount,
      'Absent': absentCount,
      'On Leave': onLeaveCount,
    };
  }

  // Get leave stats
  Map<String, int> getLeaveStats() {
    return {
      'Pending': pendingLeavesCount,
      'Approved': approvedLeavesCount,
      'Today': onLeaveCount,
    };
  }

  // Generate list of months for picker
  List<Map<String, String>> getAvailableMonths() {
    final List<Map<String, String>> months = [];
    final now = DateTime.now();

    // Add current month and previous 11 months (12 months total)
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      months.add({
        'value': DateFormat('yyyy-MM').format(date),
        'display': DateFormat('MMMM yyyy').format(date),
      });
    }

    return months;
  }
}
