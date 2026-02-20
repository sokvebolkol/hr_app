import 'package:flutter/foundation.dart';
import '../models/attendance_adjustment_model.dart';
import '../repositories/attendance_repository.dart';

class AttendanceAdjustmentViewModel extends ChangeNotifier {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();

  AttendanceAdjustmentData? _data;
  bool _isLoading = false;
  String _errorMessage = '';
  List<AttendanceMissing> _selectedAttendance = [];
  String _reason = '';

  // Getters
  AttendanceAdjustmentData? get data => _data;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<AttendanceMissing> get selectedAttendance => _selectedAttendance;
  String get reason => _reason;
  bool get canSubmit =>
      _selectedAttendance.isNotEmpty && _reason.trim().isNotEmpty;

  int get selectedCount => _selectedAttendance.length;

  bool get canRequestMore => _data?.requestLimit.canRequest ?? false;

  // Load attendance adjustment data
  Future<void> loadAttendanceData() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _attendanceRepository.getAttendanceForAdjustment();

      if (response['success'] == true) {
        final adjustmentResponse = AttendanceAdjustmentResponse.fromJson(
          response,
        );
        _data = adjustmentResponse.data;
      } else {
        throw Exception(
          response['message'] ?? 'Failed to load attendance data',
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to load attendance data: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Toggle attendance selection
  void toggleAttendanceSelection(AttendanceMissing attendance) {
    final index = _data?.attendanceMissing.indexWhere(
      (a) => a.date == attendance.date,
    );
    if (index != null && index != -1) {
      _data!.attendanceMissing[index].isSelected =
          !_data!.attendanceMissing[index].isSelected;

      if (_data!.attendanceMissing[index].isSelected) {
        _selectedAttendance.add(_data!.attendanceMissing[index]);
      } else {
        _selectedAttendance.removeWhere((a) => a.date == attendance.date);
      }
      notifyListeners();
    }
  }

  // Update reason
  void updateReason(String reason) {
    _reason = reason;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedAttendance.clear();
    if (_data != null) {
      for (var attendance in _data!.attendanceMissing) {
        attendance.isSelected = false;
      }
    }
    notifyListeners();
  }

  // Submit request
  Future<bool> submitRequest() async {
    if (!canSubmit || !canRequestMore) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // TODO: Replace with actual API call
      // final request = AttendanceAdjustmentRequest(
      //   selectedDates: _selectedAttendance.map((a) => a.date).toList(),
      //   reason: _reason,
      //   requestType: 'attendance_adjustment',
      // );

      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful submission
      _selectedAttendance.clear();
      _reason = '';

      // Update request limit
      if (_data != null) {
        final updatedUsed = _data!.requestLimit.requestsUsed + 1;
        final updatedRemaining = _data!.requestLimit.requestsRemaining - 1;

        _data = AttendanceAdjustmentData(
          userInfo: _data!.userInfo,
          approvers: _data!.approvers,
          attendanceMissing:
              _data!.attendanceMissing.map((a) {
                a.isSelected = false;
                return a;
              }).toList(),
          attendanceReports: _data!.attendanceReports,
          requestLimit: RequestLimit(
            monthlyLimit: _data!.requestLimit.monthlyLimit,
            requestsUsed: updatedUsed,
            requestsRemaining: updatedRemaining,
            canRequest: updatedRemaining > 0,
            currentMonth: _data!.requestLimit.currentMonth,
          ),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await loadAttendanceData();
  }
}
