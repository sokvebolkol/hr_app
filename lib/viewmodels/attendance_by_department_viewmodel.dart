import 'package:flutter/material.dart';
import '../models/attendance_by_department_model.dart';
import '../repositories/attendance_by_department_repository.dart';

class AttendanceByDepartmentViewModel extends ChangeNotifier {
  final AttendanceByDepartmentRepository _repository =
      AttendanceByDepartmentRepository();

  AttendanceByDepartmentData? _attendanceData;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedDepartment; // For filtering by department
  String _searchQuery = ''; // For searching staff

  AttendanceByDepartmentData? get attendanceData => _attendanceData;
  bool get isLoading                             => _isLoading;
  String? get errorMessage                       => _errorMessage;

  // Getters for filtered data
  List<Department> get departments {
    if (_attendanceData == null) return [];
    return _attendanceData!.departments;
  }

  OverallSummary? get overallSummary => _attendanceData?.overallSummary;
  DateRange? get dateRange => _attendanceData?.dateRange;

  int get totalLeave =>
      _attendanceData?.overallSummary.totalLeaveOccurrences ?? 0;
  int get totalDepartments =>
      _attendanceData?.overallSummary.totalDepartments ?? 0;

  Future<void> initialize({String? startDate, String? endDate}) async {
    await fetchAttendanceByDepartment(startDate: startDate, endDate: endDate);
  }

  Future<void> fetchAttendanceByDepartment({
    String? startDate,
    String? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getAttendanceByDepartment(
        startDate: startDate,
        endDate: endDate,
      );

      if (response.success) {
        _attendanceData = response.data;
        _errorMessage = null;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = 'Failed to load attendance data: ${e.toString()}';
      print('Error in fetchAttendanceByDepartment: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearFilters() {
    _selectedDepartment = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> refresh({String? startDate, String? endDate}) async {
    await fetchAttendanceByDepartment(startDate: startDate, endDate: endDate);
  }

}
