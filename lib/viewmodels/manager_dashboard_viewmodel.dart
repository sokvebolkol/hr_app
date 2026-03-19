import 'package:flutter/material.dart';
import '../models/ceo_dashboard_model.dart';
import '../repositories/manager_dashboard_repository.dart';

class ManagerDashboardViewModel extends ChangeNotifier {
  final ManagerDashboardRepository _repository = ManagerDashboardRepository();

  // State variables
  AttendanceSummary? _attendanceSummary;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AttendanceSummary? get attendanceSummary => _attendanceSummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
  double get attendanceRate => _attendanceSummary?.attendanceRate ?? 0;

  List<LeaveRequest> get pendingLeaves =>
      _attendanceSummary?.leaveNeedToApprove ?? [];
  List<LeaveRequest> get approvedLeaves =>
      _attendanceSummary?.approvedLeaves ?? [];
  List<LeaveRequest> get rejectedLeaves =>
      _attendanceSummary?.rejectedLeaves ?? [];
  List<AttendanceAdjustmentRequest> get pendingAttendanceRequests =>
      _attendanceSummary?.pendingAttendanceNeedToApprove ?? [];

  // Initialize
  void initialize() {
    loadAttendanceSummary();
  }

  // Load attendance summary
  Future<void> loadAttendanceSummary() async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _repository.getAttendanceSummary();
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

  // Refresh data
  Future<void> refresh() async {
    await loadAttendanceSummary();
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
