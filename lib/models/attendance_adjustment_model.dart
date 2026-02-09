// Models for Attendance Adjustment Request feature

class AttendanceAdjustmentResponse {
  final bool success;
  final String message;
  final AttendanceAdjustmentData data;

  AttendanceAdjustmentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttendanceAdjustmentResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceAdjustmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: AttendanceAdjustmentData.fromJson(json['data'] ?? {}),
    );
  }
}

class AttendanceAdjustmentData {
  final UserInfo userInfo;
  final List<Approver> approvers;
  final List<AttendanceMissing> attendanceMissing;
  final List<dynamic> attendanceReports;
  final RequestLimit requestLimit;

  AttendanceAdjustmentData({
    required this.userInfo,
    required this.approvers,
    required this.attendanceMissing,
    required this.attendanceReports,
    required this.requestLimit,
  });

  factory AttendanceAdjustmentData.fromJson(Map<String, dynamic> json) {
    return AttendanceAdjustmentData(
      userInfo: UserInfo.fromJson(json['user_info'] ?? {}),
      approvers:
          (json['approvers'] as List<dynamic>?)
              ?.map((item) => Approver.fromJson(item))
              .toList() ??
          [],
      attendanceMissing:
          (json['missing_attendance'] as List<dynamic>?)
              ?.map((item) => AttendanceMissing.fromJson(item))
              .toList() ??
          [],
      attendanceReports: json['attendance_reports'] ?? [],
      requestLimit: RequestLimit.fromJson(json['request_limit'] ?? {}),
    );
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
      employeeId: json['employee_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      username: json['username'] ?? '',
    );
  }
}

class Approver {
  final int id;
  final int requesterId;
  final int approverId;
  final int approvalLevel;
  final String createdAt;
  final String updatedAt;
  final String dname;
  final String approverLevelName;

  Approver({
    required this.id,
    required this.requesterId,
    required this.approverId,
    required this.approvalLevel,
    required this.createdAt,
    required this.updatedAt,
    required this.dname,
    required this.approverLevelName,
  });

  factory Approver.fromJson(Map<String, dynamic> json) {
    return Approver(
      id: json['id'] ?? 0,
      requesterId: json['requester_id'] ?? 0,
      approverId: json['approver_id'] ?? 0,
      approvalLevel: json['approval_level'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      dname: json['dname'] ?? '',
      approverLevelName: json['approver_level_name'] ?? '',
    );
  }
}

class AttendanceMissing {
  final String date;
  final String formattedDate;
  final String dayOfWeek;
  final bool isWeekend;
  final bool isHoliday;
  final String? scanIn;
  final String? scanOut;
  final String? clockIn;
  final String? clockOut;
  final double? workingHours;
  final String status;
  final dynamic holidayDetails;
  final dynamic leaveDetails;
  bool isSelected;

  AttendanceMissing({
    required this.date,
    required this.formattedDate,
    required this.dayOfWeek,
    required this.isWeekend,
    required this.isHoliday,
    this.scanIn,
    this.scanOut,
    this.clockIn,
    this.clockOut,
    this.workingHours,
    required this.status,
    this.holidayDetails,
    this.leaveDetails,
    this.isSelected = false,
  });

  factory AttendanceMissing.fromJson(Map<String, dynamic> json) {
    return AttendanceMissing(
      date: json['date'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      isWeekend: json['is_weekend'] ?? false,
      isHoliday: json['is_holiday'] ?? false,
      scanIn: json['scan_in'],
      scanOut: json['scan_out'],
      clockIn: json['clock_in'],
      clockOut: json['clock_out'],
      workingHours: json['working_hours']?.toDouble(),
      status: json['status'] ?? '',
      holidayDetails: json['holiday_details'],
      leaveDetails: json['leave_details'],
      isSelected: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'formatted_date': formattedDate,
      'day_of_week': dayOfWeek,
      'is_weekend': isWeekend,
      'is_holiday': isHoliday,
      'scan_in': scanIn,
      'scan_out': scanOut,
      'clock_in': clockIn,
      'clock_out': clockOut,
      'working_hours': workingHours,
      'status': status,
      'holiday_details': holidayDetails,
      'leave_details': leaveDetails,
    };
  }

  // Helper getters for backward compatibility
  String get checkedIn => scanIn ?? clockIn ?? '';
  String get checkedOut => scanOut ?? clockOut ?? '';
}

class RequestLimit {
  final int monthlyLimit;
  final int requestsUsed;
  final int requestsRemaining;
  final bool canRequest;
  final String currentMonth;

  RequestLimit({
    required this.monthlyLimit,
    required this.requestsUsed,
    required this.requestsRemaining,
    required this.canRequest,
    required this.currentMonth,
  });

  factory RequestLimit.fromJson(Map<String, dynamic> json) {
    return RequestLimit(
      monthlyLimit: json['monthly_limit'] ?? 0,
      requestsUsed: json['requests_used'] ?? 0,
      requestsRemaining: json['requests_remaining'] ?? 0,
      canRequest: json['can_request'] ?? false,
      currentMonth: json['current_month'] ?? '',
    );
  }
}

class AttendanceAdjustmentRequest {
  final List<String> selectedDates;
  final String reason;
  final String requestType;

  AttendanceAdjustmentRequest({
    required this.selectedDates,
    required this.reason,
    required this.requestType,
  });

  Map<String, dynamic> toJson() {
    return {
      'selected_dates': selectedDates,
      'reason': reason,
      'request_type': requestType,
    };
  }
}
