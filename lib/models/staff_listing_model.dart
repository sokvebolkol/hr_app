class StaffListingResponse {
  final bool success;
  final StaffListingData data;

  StaffListingResponse({required this.success, required this.data});

  factory StaffListingResponse.fromJson(Map<String, dynamic> json) {
    return StaffListingResponse(
      success: json['success'] ?? false,
      data: StaffListingData.fromJson(json['data'] ?? {}),
    );
  }
}

class StaffListingData {
  final DateInfo dateInfo;
  final FilterInfo filterInfo;
  final FilterOptions filterOptions;
  final SummaryStats summaryStats;
  final List<StaffMember> staffListing;
  final PaginationInfo pagination;

  StaffListingData({
    required this.dateInfo,
    required this.filterInfo,
    required this.filterOptions,
    required this.summaryStats,
    required this.staffListing,
    required this.pagination,
  });

  factory StaffListingData.fromJson(Map<String, dynamic> json) {
    return StaffListingData(
      dateInfo: DateInfo.fromJson(json['date_info'] ?? {}),
      filterInfo: FilterInfo.fromJson(json['filter_info'] ?? {}),
      filterOptions: FilterOptions.fromJson(json['filter_options'] ?? {}),
      summaryStats: SummaryStats.fromJson(json['summary_stats'] ?? {}),
      staffListing:
          (json['staff_listing'] as List?)
              ?.map((x) => StaffMember.fromJson(x))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class DateInfo {
  final String date;
  final String formattedDate;
  final String dayOfWeek;
  final bool isWeekend;
  final bool isHoliday;
  final String? holidayName;

  DateInfo({
    required this.date,
    required this.formattedDate,
    required this.dayOfWeek,
    required this.isWeekend,
    required this.isHoliday,
    this.holidayName,
  });

  factory DateInfo.fromJson(Map<String, dynamic> json) {
    return DateInfo(
      date: json['date'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      isWeekend: json['is_weekend'] ?? false,
      isHoliday: json['is_holiday'] ?? false,
      holidayName: json['holiday_name'],
    );
  }
}

class FilterInfo {
  final String status;
  final String? branchId;
  final String? departmentId;

  FilterInfo({required this.status, this.branchId, this.departmentId});

  factory FilterInfo.fromJson(Map<String, dynamic> json) {
    return FilterInfo(
      status: json['status'] ?? 'all',
      branchId: json['branch_id'],
      departmentId: json['department_id'],
    );
  }
}

class FilterOptions {
  final List<Branch> branches;
  final List<Department> departments;
  final List<StatusOption> statusOptions;

  FilterOptions({
    required this.branches,
    required this.departments,
    required this.statusOptions,
  });

  factory FilterOptions.fromJson(Map<String, dynamic> json) {
    return FilterOptions(
      branches:
          (json['branches'] as List?)
              ?.map((x) => Branch.fromJson(x))
              .toList() ??
          [],
      departments:
          (json['departments'] as List?)
              ?.map((x) => Department.fromJson(x))
              .toList() ??
          [],
      statusOptions:
          (json['status_options'] as List?)
              ?.map((x) => StatusOption.fromJson(x))
              .toList() ??
          [],
    );
  }
}

class Branch {
  final String branchId;
  final String branchShortName;
  final String branchFullName;

  Branch({
    required this.branchId,
    required this.branchShortName,
    required this.branchFullName,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: json['branch_id']?.toString() ?? '',
      branchShortName: json['branch_short_name'] ?? '',
      branchFullName: json['branch_full_name'] ?? '',
    );
  }
}

class Department {
  final String departmentId;
  final String departmentName;

  Department({required this.departmentId, required this.departmentName});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['department_id']?.toString() ?? '',
      departmentName: json['department_name'] ?? '',
    );
  }
}

class StatusOption {
  final String value;
  final String label;

  StatusOption({required this.value, required this.label});

  factory StatusOption.fromJson(Map<String, dynamic> json) {
    return StatusOption(value: json['value'] ?? '', label: json['label'] ?? '');
  }
}

class SummaryStats {
  final int totalStaff;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int leaveCount;
  final int weekendCount;
  final int holidayCount;
  final int filteredCount;

  SummaryStats({
    required this.totalStaff,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.leaveCount,
    required this.weekendCount,
    required this.holidayCount,
    required this.filteredCount,
  });

  factory SummaryStats.fromJson(Map<String, dynamic> json) {
    return SummaryStats(
      totalStaff: _parseToInt(json['total_staff']),
      presentCount: _parseToInt(json['present_count']),
      lateCount: _parseToInt(json['late_count']),
      absentCount: _parseToInt(json['absent_count']),
      leaveCount: _parseToInt(json['leave_count']),
      weekendCount: _parseToInt(json['weekend_count']),
      holidayCount: _parseToInt(json['holiday_count']),
      filteredCount: _parseToInt(json['filtered_count']),
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.round();
    return 0;
  }
}

class StaffMember {
  final String employeeId;
  final String staffId;
  final String fullName;
  final String? email;
  final String? phone;
  final String positionName;
  final String departmentName;
  final String branchShortName;
  final String branchFullName;
  final String date;
  final String formattedDate;
  final String dayOfWeek;
  final String category;
  final String status;
  final String statusDetail;
  final AttendanceDetails attendanceDetails;
  final LeaveDetails? leaveDetails;

  StaffMember({
    required this.employeeId,
    required this.staffId,
    required this.fullName,
    this.email,
    this.phone,
    required this.positionName,
    required this.departmentName,
    required this.branchShortName,
    required this.branchFullName,
    required this.date,
    required this.formattedDate,
    required this.dayOfWeek,
    required this.category,
    required this.status,
    required this.statusDetail,
    required this.attendanceDetails,
    this.leaveDetails,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      employeeId: json['employee_id']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      positionName: json['position_name'] ?? '',
      departmentName: json['department_name'] ?? '',
      branchShortName: json['branch_short_name'] ?? '',
      branchFullName: json['branch_full_name'] ?? '',
      date: json['date'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
      dayOfWeek: json['day_of_week'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      statusDetail: json['status_detail'] ?? '',
      attendanceDetails: AttendanceDetails.fromJson(
        json['attendance_details'] ?? {},
      ),
      leaveDetails:
          json['leave_details'] != null
              ? LeaveDetails.fromJson(json['leave_details'])
              : null,
    );
  }
}

class AttendanceDetails {
  final String? clockIn;
  final String? clockOut;
  final String? scanIn;
  final String? scanOut;
  final String? checkIn;
  final String? checkOut;
  final String? workingHours;

  AttendanceDetails({
    this.clockIn,
    this.clockOut,
    this.scanIn,
    this.scanOut,
    this.checkIn,
    this.checkOut,
    this.workingHours,
  });

  factory AttendanceDetails.fromJson(Map<String, dynamic> json) {
    return AttendanceDetails(
      clockIn: json['clock_in']?.toString(),
      clockOut: json['clock_out']?.toString(),
      scanIn: json['scan_in']?.toString(),
      scanOut: json['scan_out']?.toString(),
      checkIn: json['check_in']?.toString(),
      checkOut: json['check_out']?.toString(),
      workingHours: json['working_hours']?.toString(),
    );
  }
}

class LeaveDetails {
  final String leaveType;
  final String reason;
  final String startDate;
  final String endDate;
  final String totalDays;

  LeaveDetails({
    required this.leaveType,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
  });

  factory LeaveDetails.fromJson(Map<String, dynamic> json) {
    return LeaveDetails(
      leaveType: json['leave_type'] ?? '',
      reason: json['reason'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      totalDays: json['total_days']?.toString() ?? '',
    );
  }
}

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final int perPage;
  final bool hasNext;
  final bool hasPrevious;
  final ShowingInfo showing;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.perPage,
    required this.hasNext,
    required this.hasPrevious,
    required this.showing,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: _parseToInt(json['current_page']) ?? 1,
      totalPages: _parseToInt(json['total_pages']) ?? 1,
      totalRecords: _parseToInt(json['total_records']) ?? 0,
      perPage: _parseToInt(json['per_page']) ?? 50,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
      showing: ShowingInfo.fromJson(json['showing'] ?? {}),
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.round();
    return 0;
  }
}

class ShowingInfo {
  final int from;
  final int to;
  final int total;

  ShowingInfo({required this.from, required this.to, required this.total});

  factory ShowingInfo.fromJson(Map<String, dynamic> json) {
    return ShowingInfo(
      from: _parseToInt(json['from']),
      to: _parseToInt(json['to']),
      total: _parseToInt(json['total']),
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.round();
    return 0;
  }
}
