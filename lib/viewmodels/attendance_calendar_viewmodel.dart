import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/attendance_calendar_model.dart';
import '../repositories/attendance_calendar_repository.dart';

class AttendanceCalendarViewModel extends ChangeNotifier {
  final AttendanceCalendarRepository _repository =
      AttendanceCalendarRepository();

  // State variables
  AttendanceCalendarData? _attendanceData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Getters
  AttendanceCalendarData? get attendanceData => _attendanceData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;

  List<AttendanceReport> get attendanceReports =>
      _attendanceData?.attendanceReports ?? [];

  AttendanceSummary? get summary => _attendanceData?.summary;
  UserInfo? get userInfo => _attendanceData?.userInfo;

  // Get attendance for a specific day
  AttendanceReport? getAttendanceForDay(DateTime day) {
    final dateString = DateFormat('yyyy-MM-dd').format(day);
    try {
      return attendanceReports.firstWhere(
        (report) => report.date == dateString,
      );
    } catch (e) {
      return null;
    }
  }

  // Get selected day attendance
  AttendanceReport? get selectedDayAttendance =>
      getAttendanceForDay(_selectedDay);

  // Initialize
  void initialize() {
    loadCurrentMonthAttendance();
  }

  // Load current month attendance
  Future<void> loadCurrentMonthAttendance() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    await loadAttendanceForDateRange(startOfMonth, endOfMonth);
  }

  // Load attendance for specific date range
  Future<void> loadAttendanceForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      _setLoading(true);
      _setError(null);

      final request = AttendanceCalendarRequest(
        startDate: DateFormat('yyyy-MM-dd').format(startDate),
        endDate: DateFormat('yyyy-MM-dd').format(endDate),
      );

      final response = await _repository.getAttendanceCalendar(request);

      if (response.success) {
        _attendanceData = response.data;
      } else {
        throw Exception('Failed to load attendance data');
      }

      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Load attendance for focused month
  Future<void> loadAttendanceForMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    await loadAttendanceForDateRange(startOfMonth, endOfMonth);
  }

  // Calendar event handlers
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    _selectedDay = selectedDay;
    _focusedDay = focusedDay;
    notifyListeners();
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    loadAttendanceForMonth(focusedDay);
    notifyListeners();
  }

  void onFormatChanged(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  // Get events for calendar
  List<AttendanceReport> getEventsForDay(DateTime day) {
    final attendance = getAttendanceForDay(day);
    return attendance != null ? [attendance] : [];
  }

  // Get attendance status color
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'on leave':
        return Colors.blue;
      case 'absent':
        return Colors.red;
      case 'weekend':
        return Colors.grey;
      default:
        if (status.toLowerCase().contains('late')) {
          return Colors.orange;
        }
        return Colors.grey;
    }
  }

  // Get attendance status icon
  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'on leave':
        return Icons.beach_access;
      case 'absent':
        return Icons.cancel;
      case 'weekend':
        return Icons.weekend;
      case 'public holiday':
        return Icons.public;
      default:
        if (status.toLowerCase().contains('late')) {
          return Icons.access_time;
        }
        return Icons.help_outline;
    }
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

  // Calculate statistics
  Map<String, int> getStatusCounts() {
    final counts = <String, int>{
      'Present': 0,
      'Absent': 0,
      'On Leave': 0,
      'Late': 0,
      'Weekend': 0,
    };

    for (final report in attendanceReports) {
      if (report.isPresent && !report.isLate) {
        counts['Present'] = (counts['Present'] ?? 0) + 1;
      } else if (report.isLate) {
        counts['Late'] = (counts['Late'] ?? 0) + 1;
      } else if (report.isOnLeave) {
        counts['On Leave'] = (counts['On Leave'] ?? 0) + 1;
      } else if (report.isWeekend) {
        counts['Weekend'] = (counts['Weekend'] ?? 0) + 1;
      } else if (report.isAbsent) {
        counts['Absent'] = (counts['Absent'] ?? 0) + 1;
      }
    }

    return counts;
  }
}
