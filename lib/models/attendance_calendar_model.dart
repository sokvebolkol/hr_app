class AttendanceCalendarResponse {
  final bool success;
  final AttendanceCalendarData data;

  AttendanceCalendarResponse({required this.success, required this.data});

  factory AttendanceCalendarResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceCalendarResponse(
      success: json['success'] ?? false,
      data: AttendanceCalendarData.fromJson(json['data']),
    );
  }
}

class AttendanceCalendarData {
  final List<AttendanceReport> attendanceReports;
  final AttendanceSummary summary;
  final UserInfo userInfo;

  AttendanceCalendarData({
    required this.attendanceReports,
    required this.summary,
    required this.userInfo,
  });

  factory AttendanceCalendarData.fromJson(Map<String, dynamic> json) {
    return AttendanceCalendarData(
      attendanceReports:
          (json['attendance_reports'] as List)
              .map((e) => AttendanceReport.fromJson(e))
              .toList(),
      summary: AttendanceSummary.fromJson(json['summary']),
      userInfo: UserInfo.fromJson(json['user_info']),
    );
  }
}

class AttendanceReport {
  final String date;
  final String formattedDate;
  final String dayOfWeek;
  final String? scanIn;
  final String? scanOut;
  final String? clockIn;
  final String? clockOut;
  final String? workingHours;
  final String status;
  final LeaveDetails? leaveDetails;

  AttendanceReport({
    required this.date,
    required this.formattedDate,
    required this.dayOfWeek,
    this.scanIn,
    this.scanOut,
    this.clockIn,
    this.clockOut,
    this.workingHours,
    required this.status,
    this.leaveDetails,
  });

  factory AttendanceReport.fromJson(Map<String, dynamic> json) {
    return AttendanceReport(
      date: json['date']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString() ?? '',
      dayOfWeek: json['day_of_week']?.toString() ?? '',
      scanIn: json['scan_in']?.toString(),
      scanOut: json['scan_out']?.toString(),
      clockIn: json['clock_in']?.toString(),
      clockOut: json['clock_out']?.toString(),
      workingHours: json['working_hours']?.toString(),
      status: json['status']?.toString() ?? '',
      leaveDetails:
          json['leave_details'] != null
              ? LeaveDetails.fromJson(json['leave_details'])
              : null,
    );
  }

  DateTime get dateTime => DateTime.parse(date);

  bool get hasAttendance => scanIn != null || clockIn != null;
  bool get isComplete =>
      (scanIn != null && scanOut != null) ||
      (clockIn != null && clockOut != null);
  bool get isWeekend => status.toLowerCase() == 'weekend';
  bool get isOnLeave => status.toLowerCase() == 'on leave';
  bool get isAbsent => status.toLowerCase() == 'absent';
  bool get isLate => status.toLowerCase().contains('late');
  bool get isPresent => hasAttendance && !isOnLeave;
}

class LeaveDetails {
  final String leaveTypeName;
  final String reason;
  final String startDate;
  final String endDate;
  final String totalDays;

  LeaveDetails({
    required this.leaveTypeName,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
  });

  factory LeaveDetails.fromJson(Map<String, dynamic> json) {
    return LeaveDetails(
      leaveTypeName: json['leave_type_name']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalDays: json['total_days']?.toString() ?? '0',
    );
  }
}

class AttendanceSummary {
  final int totalDays;
  final int daysWithData;
  final int daysWithoutData;
  final int completeDays;
  final int daysWithPhoneData;
  final int daysWithFingerprintData;
  final DateRange dateRange;

  AttendanceSummary({
    required this.totalDays,
    required this.daysWithData,
    required this.daysWithoutData,
    required this.completeDays,
    required this.daysWithPhoneData,
    required this.daysWithFingerprintData,
    required this.dateRange,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: _parseToInt(json['total_days']),
      daysWithData: _parseToInt(json['days_with_data']),
      daysWithoutData: _parseToInt(json['days_without_data']),
      completeDays: _parseToInt(json['complete_days']),
      daysWithPhoneData: _parseToInt(json['days_with_phone_data']),
      daysWithFingerprintData: _parseToInt(json['days_with_fingerprint_data']),
      dateRange: DateRange.fromJson(json['date_range']),
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double get attendanceRate =>
      totalDays > 0 ? (daysWithData / totalDays) * 100 : 0;
}

class DateRange {
  final String startDate;
  final String endDate;
  final int totalDaysInRange;

  DateRange({
    required this.startDate,
    required this.endDate,
    required this.totalDaysInRange,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      totalDaysInRange: _parseToInt(json['total_days_in_range']),
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class UserInfo {
  final String employeeId;
  final String staffId;
  final String username;

  UserInfo({
    required this.employeeId,
    required this.staffId,
    required this.username,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      employeeId: json['employee_id']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

class AttendanceCalendarRequest {
  final String startDate;
  final String endDate;

  AttendanceCalendarRequest({required this.startDate, required this.endDate});

  Map<String, dynamic> toJson() {
    return {'start_date': startDate, 'end_date': endDate};
  }
}
