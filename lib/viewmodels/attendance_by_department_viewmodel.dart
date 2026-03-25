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
  String? get selectedDepartment                 => _selectedDepartment;
  String get searchQuery                         => _searchQuery;

  // Getters for filtered data
  List<Department> get departments {
    if (_attendanceData == null) return [];
    return _attendanceData!.departments;
  }

  List<Department> get filteredDepartments {
    if (_attendanceData == null) return [];

    var depts = _attendanceData!.departments;

    // Filter by selected department if any
    if (_selectedDepartment != null && _selectedDepartment != 'All') {
      depts =
          depts
              .where((dept) => dept.departmentId == _selectedDepartment)
              .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      depts =
          depts.where((dept) {
            // Search in department name
            if (dept.departmentName.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            )) {
              return true;
            }
            // Search in staff members
            return dept.staffMembers.any(
              (staff) =>
                  staff.fullName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  staff.staffId.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  staff.email.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            );
          }).toList();
    }

    return depts;
  }

  OverallSummary? get overallSummary => _attendanceData?.overallSummary;
  DateRange? get dateRange => _attendanceData?.dateRange;

  // Statistics
  int get totalLate =>
      _attendanceData?.overallSummary.totalLateOccurrences ?? 0;
  int get totalLeave =>
      _attendanceData?.overallSummary.totalLeaveOccurrences ?? 0;
  int get totalAbsent =>
      _attendanceData?.overallSummary.totalAbsentOccurrences ?? 0;
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

  void setSelectedDepartment(String? departmentId) {
    _selectedDepartment = departmentId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedDepartment = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> refresh({String? startDate, String? endDate}) async {
    await fetchAttendanceByDepartment(startDate: startDate, endDate: endDate);
  }

  // Get departments with issues only
  List<Department> get departmentsWithIssues {
    if (_attendanceData == null) return [];
    return _attendanceData!.departments.where((dept) {
      final counts = dept.attendanceCounts;
      return counts.late > 0 || counts.leave > 0 || counts.absent > 0;
    }).toList();
  }

  // Get all staff with issues across all departments
  List<StaffMember> get allStaffWithIssues {
    if (_attendanceData == null) return [];
    List<StaffMember> staffWithIssues = [];
    for (var dept in _attendanceData!.departments) {
      staffWithIssues.addAll(
        dept.staffMembers.where((staff) => staff.hasIssues),
      );
    }
    return staffWithIssues;
  }
}
