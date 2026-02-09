import 'package:flutter/foundation.dart';
import '../models/attendance_adjustment_model.dart';

class AttendanceAdjustmentViewModel extends ChangeNotifier {
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
      // TODO: Replace with actual API call
      // For now, using the provided sample data
      await Future.delayed(const Duration(milliseconds: 500));

      final sampleData = {
        "success": true,
        "data": {
          "user_info": {
            "employee_id": "200510",
            "staff_id": "0892",
            "username": "KOL SOKVEBOL",
          },
          "approvers": [
            {
              "id": 1465,
              "requester_id": 200510,
              "approver_id": 200619,
              "approval_level": 2,
              "created_at": "2026-02-02 03:52:20.667",
              "updated_at": "2026-02-02 03:52:20.667",
              "dname": "MOEUN SREYMOM",
              "approver_level_name": "Second Approver",
            },
            {
              "id": 1466,
              "requester_id": 200510,
              "approver_id": 200075,
              "approval_level": 98,
              "created_at": "2026-02-02 03:52:20.667",
              "updated_at": "2026-02-02 03:52:20.667",
              "dname": "LANG DALIN",
              "approver_level_name": "HR (Default)",
            },
          ],
          "request_limit": {
            "monthly_limit": 4,
            "requests_used": 1,
            "requests_remaining": 3,
            "can_request": true,
            "current_month": "2026-02",
          },
          "attendance_reports": [],
          "missing_attendance": [
            {
              "date": "2026-02-03",
              "formatted_date": "Feb 03, 2026",
              "day_of_week": "Tuesday",
              "is_weekend": false,
              "is_holiday": false,
              "scan_in": null,
              "scan_out": null,
              "clock_in": "10:55",
              "clock_out": null,
              "working_hours": null,
              "status": "No Check-Out",
              "holiday_details": null,
              "leave_details": null,
            },
            {
              "date": "2026-01-30",
              "formatted_date": "Jan 30, 2026",
              "day_of_week": "Friday",
              "is_weekend": false,
              "is_holiday": false,
              "scan_in": "07:55",
              "scan_out": null,
              "clock_in": null,
              "clock_out": null,
              "working_hours": null,
              "status": "No Check-Out",
              "holiday_details": null,
              "leave_details": null,
            },
            {
              "date": "2026-01-28",
              "formatted_date": "Jan 28, 2026",
              "day_of_week": "Wednesday",
              "is_weekend": false,
              "is_holiday": false,
              "scan_in": "07:59",
              "scan_out": "",
              "clock_in": null,
              "clock_out": null,
              "working_hours": null,
              "status": "No Check-Out",
              "holiday_details": null,
              "leave_details": null,
            },
          ],
        },
      };

      final response = AttendanceAdjustmentResponse.fromJson(sampleData);
      _data = response.data;
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
