import 'package:flutter/material.dart';
import '../models/ceo_dashboard_model.dart';
import '../repositories/manager_dashboard_repository.dart';

class ManagerDashboardViewModel extends ChangeNotifier {
  final ManagerDashboardRepository _repository = ManagerDashboardRepository();

  // State variables
  AttendanceSummary? _attendanceSummary;
  bool _isLoading = false;
  String? _errorMessage;

  /// Month currently applied to the attendance history, as `YYYY-MM`.
  /// Null means "All", i.e. the API's default of the last 12 months.
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
  int get pendingAttendanceCount =>
      _attendanceSummary?.pendingAttendanceCount ?? 0;
  int get totalPendingApprovals =>
      _attendanceSummary?.totalPendingApprovals ?? 0;
  int get approvedLeavesCount => _attendanceSummary?.approvedLeavesCount ?? 0;
  int get rejectedLeavesCount => _attendanceSummary?.rejectedLeavesCount ?? 0;
  int get approvedAttendanceCount =>
      _attendanceSummary?.approvedAttendanceCount ?? 0;
  int get rejectedAttendanceCount =>
      _attendanceSummary?.rejectedAttendanceCount ?? 0;
  double get attendanceRate => _attendanceSummary?.attendanceRate ?? 0;

  List<LeaveRequest> get pendingLeaves =>
      _attendanceSummary?.leaveNeedToApprove ?? [];
  List<LeaveRequest> get approvedLeaves =>
      _attendanceSummary?.approvedLeaves ?? [];
  List<LeaveRequest> get rejectedLeaves =>
      _attendanceSummary?.rejectedLeaves ?? [];
  List<AttendanceAdjustmentRequest> get pendingAttendanceRequests =>
      _attendanceSummary?.pendingAttendanceNeedToApprove ?? [];
  List<AttendanceAdjustmentRequest> get approvedAttendanceRequests =>
      _attendanceSummary?.approvedAttendance ?? [];
  List<AttendanceAdjustmentRequest> get rejectedAttendanceRequests =>
      _attendanceSummary?.rejectedAttendance ?? [];

  // Initialize
  void initialize({String? month}) {
    loadAttendanceSummary(month: month);
  }

  /// Loads the dashboard summary.
  ///
  /// [month] is `YYYY-MM` (e.g. `2026-09`) and scopes `approved_attendance`,
  /// `rejected_attendance` and their counts to that month. Pass null for
  /// "All", which leaves the API on its default of the last 12 months.
  ///
  /// The value is remembered so [refresh] re-applies the same filter.
  Future<void> loadAttendanceSummary({String? month}) async {
    try {
      _selectedMonth = month;
      _setLoading(true);
      _setError(null);

      final response = await _repository.getAttendanceSummary(month: month);
      if (response.success) {
        _attendanceSummary = response.data.summary;
      } else {
        final errorMessage =
            'Failed to load dashboard data - API returned success: false';
        _setError(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'An unexpected error occurred: $e';
      _setError(errorMessage);
      if (e is Exception) {
        print('Exception message: ${e.toString()}');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Reloads using the month filter already in effect, so a pull-to-refresh
  /// does not silently reset the view back to "All".
  Future<void> refresh() async {
    if (_isLoading) return; // reuse the load already in flight
    await loadAttendanceSummary(month: _selectedMonth);
  }

  /// Converts a picker label such as "September 2026" into the `YYYY-MM`
  /// the API expects. Returns null for "All" or anything unparseable, which
  /// the caller should treat as "no month filter".
  static String? toApiMonth(String? label, DateTime? date) {
    if (label == null || label == 'All' || date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
