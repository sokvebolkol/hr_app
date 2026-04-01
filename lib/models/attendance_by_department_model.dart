class AttendanceByDepartmentResponse {
  final bool success;
  final String message;
  final AttendanceByDepartmentData data;

  AttendanceByDepartmentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AttendanceByDepartmentResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceByDepartmentResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: AttendanceByDepartmentData.fromJson(json['data'] ?? {}),
    );
  }
}

class AttendanceByDepartmentData {
  final DateRange dateRange;
  final List<Department> departments;
  final OverallSummary overallSummary;

  AttendanceByDepartmentData({
    required this.dateRange,
    required this.departments,
    required this.overallSummary,
  });

  factory AttendanceByDepartmentData.fromJson(Map<String, dynamic> json) {
    return AttendanceByDepartmentData(
      dateRange: DateRange.fromJson(json['date_range'] ?? {}),
      departments:
          (json['departments'] as List<dynamic>?)
              ?.map((e) => Department.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overallSummary: OverallSummary.fromJson(json['overall_summary'] ?? {}),
    );
  }
}

class DateRange {
  final String startDate;
  final String endDate;
  final String formattedStart;
  final String formattedEnd;

  DateRange({
    required this.startDate,
    required this.endDate,
    required this.formattedStart,
    required this.formattedEnd,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      formattedStart: json['formatted_start'] ?? '',
      formattedEnd: json['formatted_end'] ?? '',
    );
  }
}

class Department {
  final String departmentId;
  final String departmentName;
  final int totalEmployees;
  final AttendanceCounts attendanceCounts;
  final UniqueStaffCounts uniqueStaffCounts;
  final List<StaffMember> staffMembers;

  Department({
    required this.departmentId,
    required this.departmentName,
    required this.totalEmployees,
    required this.attendanceCounts,
    required this.uniqueStaffCounts,
    required this.staffMembers,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['department_id'] ?? '',
      departmentName: json['department_name'] ?? '',
      totalEmployees: json['total_employees'] ?? 0,
      attendanceCounts: AttendanceCounts.fromJson(
        json['attendance_counts'] ?? {},
      ),
      uniqueStaffCounts: UniqueStaffCounts.fromJson(
        json['unique_staff_counts'] ?? {},
      ),
      staffMembers:
          (json['staff_members'] as List<dynamic>?)
              ?.map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AttendanceCounts {
  final int late;
  final int leave;
  final int absent;

  AttendanceCounts({
    required this.late,
    required this.leave,
    required this.absent,
  });

  factory AttendanceCounts.fromJson(Map<String, dynamic> json) {
    return AttendanceCounts(
      late: json['late'] ?? 0,
      leave: json['leave'] ?? 0,
      absent: json['absent'] ?? 0,
    );
  }
}

class UniqueStaffCounts {
  final int staffWithLate;
  final int staffWithLeave;
  final int staffWithAbsent;

  UniqueStaffCounts({
    required this.staffWithLate,
    required this.staffWithLeave,
    required this.staffWithAbsent,
  });

  factory UniqueStaffCounts.fromJson(Map<String, dynamic> json) {
    return UniqueStaffCounts(
      staffWithLate: json['staff_with_late'] ?? 0,
      staffWithLeave: json['staff_with_leave'] ?? 0,
      staffWithAbsent: json['staff_with_absent'] ?? 0,
    );
  }
}

class DailyRecord {
  final String date;
  final String? clockIn;
  final String? clockOut;
  final bool? isLate;

  /// Raw attendance type returned by the API (e.g. 'leave', 'absent', 'present', 'late').
  final String? attendanceType;

  DailyRecord({
    required this.date,
    this.clockIn,
    this.clockOut,
    this.isLate,
    this.attendanceType,
  });

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: json['date'] ?? '',
      clockIn: json['clock_in'],
      clockOut: json['clock_out'],
      isLate:
          json['clock_in'] != null
              ? (json['clock_in'] as String).compareTo('08:05') > 0
              : null,
      attendanceType:
          (json['attendance_type'] ?? json['status'] ?? json['type'])
              ?.toString()
              .toLowerCase(),
    );
  }
}

class StaffMember {
  final String employeeId;
  final String staffId;
  final String fullName;
  final String email;
  final String positionName;
  final String branchShortName;
  final String branchFullName;
  final int lateCount;
  final int leaveCount;
  final int absentCount;
  final List<DailyRecord> dailyRecords;

  StaffMember({
    required this.employeeId,
    required this.staffId,
    required this.fullName,
    required this.email,
    required this.positionName,
    required this.branchShortName,
    required this.branchFullName,
    required this.lateCount,
    required this.leaveCount,
    required this.absentCount,
    required this.dailyRecords,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      employeeId: json['employee_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      positionName: json['position_name'] ?? '',
      branchShortName: json['branch_short_name'] ?? '',
      branchFullName: json['branch_full_name'] ?? '',
      lateCount: json['late_count'] ?? 0,
      leaveCount: json['leave_count'] ?? 0,
      absentCount: json['absent_count'] ?? 0,
      dailyRecords:
          (json['daily_records'] as List<dynamic>?)
              ?.map((e) => DailyRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Helper method to get clock in time (returns first available)
  String? get clockIn {
    if (dailyRecords.isEmpty) return null;
    return dailyRecords.first.clockIn;
  }

  // Helper method to get clock out time (returns first available)
  String? get clockOut {
    if (dailyRecords.isEmpty) return null;
    return dailyRecords.first.clockOut;
  }

  bool get hasIssues => lateCount > 0 || leaveCount > 0 || absentCount > 0;
}

class OverallSummary {
  final int totalDepartments;
  final int totalPresentOccurrences;
  final int totalLateOccurrences;
  final int totalLeaveOccurrences;
  final int totalAbsentOccurrences;

  OverallSummary({
    required this.totalPresentOccurrences,
    required this.totalDepartments,
    required this.totalLateOccurrences,
    required this.totalLeaveOccurrences,
    required this.totalAbsentOccurrences,
  });

  factory OverallSummary.fromJson(Map<String, dynamic> json) {
    return OverallSummary(
      totalDepartments: json['total_departments'] ?? 0,
      totalPresentOccurrences: json['total_present_occurrences'] ?? 0,
      totalLateOccurrences: json['total_late_occurrences'] ?? 0,
      totalLeaveOccurrences: json['total_leave_occurrences'] ?? 0,
      totalAbsentOccurrences: json['total_absent_occurrences'] ?? 0,
    );
  }

  int get totalIssues =>
      totalLateOccurrences + totalLeaveOccurrences + totalAbsentOccurrences;
}
