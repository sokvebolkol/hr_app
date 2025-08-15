class AttendanceLog {
  final String timeId;
  final String empId;
  final String branchCode;
  final DateTime timeDate;
  final String timeClock;
  final String deviceName;
  final String status;
  final UserProfileInfo? userInfoProfile;

  AttendanceLog({
    required this.timeId,
    required this.empId,
    required this.branchCode,
    required this.timeDate,
    required this.timeClock,
    required this.deviceName,
    required this.status,
    required this.userInfoProfile,
  });

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    return AttendanceLog(
      timeId: json['timid'] ?? '',
      empId: json['eid'] ?? '',
      branchCode: json['braid'] ?? '',
      timeDate: DateTime.parse(
        json['tdate'] ?? DateTime.now().toIso8601String(),
      ),
      timeClock: json['tim'] ?? '',
      deviceName: json['cty'] ?? '',
      status: json['sta'] ?? '',
      userInfoProfile: UserProfileInfo.fromJson(json['ccfpinfo'] ?? {}),
    );
  }
}

class UserProfileInfo {
  final String empId;
  final String empIdCard;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String employeePosition;

  UserProfileInfo({
    required this.empId,
    required this.empIdCard,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    required this.employeePosition,
  });

  factory UserProfileInfo.fromJson(Map<String, dynamic> json) {
    return UserProfileInfo(
      empId: json['eid'] ?? '',
      empIdCard: json['ecard'] ?? '',
      firstName: json['fname'] ?? '',
      lastName: json['lname'] ?? '',
      fullName: json['dname'] ?? '',
      email: json['email'] ?? '',
      employeePosition: json['employeeposition'] ?? '',
    );
  }
}

class AttendanceResponse {
  final int totalList;
  final String lastStatus;
  final List<AttendanceLog> attendanceLogs;

  AttendanceResponse({
    required this.totalList,
    required this.lastStatus,
    required this.attendanceLogs,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    var logs = json['attendanceLogs'] as List? ?? [];
    List<AttendanceLog> attendanceLogsList =
        logs.map((i) => AttendanceLog.fromJson(i)).toList();

    return AttendanceResponse(
      totalList: json['totalList'] ?? 0,
      lastStatus: json['lastStatus'] ?? '',
      attendanceLogs: attendanceLogsList,
    );
  }
}

class AttendanceClockData {
  final UserInfo user;
  final int rangeAllowClock;
  final bool isAlreadyScanInFingerprint;
  final List<AttendanceRecord> attendance;
  final List<Branch> branches;

  AttendanceClockData({
    required this.user,
    required this.rangeAllowClock,
    required this.isAlreadyScanInFingerprint,
    required this.attendance,
    required this.branches,
  });

  factory AttendanceClockData.fromJson(Map<String, dynamic> json) {
    return AttendanceClockData(
      user: UserInfo.fromJson(json['user']),
      rangeAllowClock: json['range_allow_clock'] ?? 300,
      isAlreadyScanInFingerprint:
          json['is_already_scan_in_fingerprint'] ?? false,
      attendance:
          (json['attendance'] as List)
              .map((e) => AttendanceRecord.fromJson(e))
              .toList(),
      branches:
          (json['branches'] as List).map((e) => Branch.fromJson(e)).toList(),
    );
  }
}

class UserInfo {
  final String uid;
  final String userName;
  final String branchId;

  UserInfo({required this.uid, required this.userName, required this.branchId});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      uid: json['uid'] ?? '',
      userName: json['user_name'] ?? '',
      branchId: json['branch_id'] ?? '',
    );
  }
}

class AttendanceRecord {
  final String branchId;
  final String timeClock;
  final String clockType;
  final DateTime clockDate;

  AttendanceRecord({
    required this.branchId,
    required this.timeClock,
    required this.clockType,
    required this.clockDate,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      branchId: json['branch_id'] ?? '',
      timeClock: json['time_clock'] ?? '',
      clockType: json['clock_type'] ?? '',
      clockDate: DateTime.parse(json['clock_date']),
    );
  }

  bool get isClockIn => clockType.toLowerCase() == 'in';
  bool get isClockOut => clockType.toLowerCase() == 'out';
}

class Branch {
  final String branchId;
  final String branchShortName;
  final String branchFullName;
  final double? latitude;
  final double? longitude;

  Branch({
    required this.branchId,
    required this.branchShortName,
    required this.branchFullName,
    this.latitude,
    this.longitude,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: json['branch_id'] ?? '',
      branchShortName: json['branch_short_name'] ?? '',
      branchFullName: json['branch_full_name'] ?? '',
      latitude:
          json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null,
    );
  }

  // Helper method to check if branch has valid coordinates
  bool get hasValidCoordinates => latitude != null && longitude != null;

  // Helper method to get coordinates as a map
  Map<String, double>? get coordinates {
    if (hasValidCoordinates) {
      return {'lat': latitude!, 'lng': longitude!};
    }
    return null;
  }
}

class ClockInOutRequest {
  final String branchId;
  final double latitude;
  final double longitude;
  final String clockType;

  ClockInOutRequest({
    required this.branchId,
    required this.latitude,
    required this.longitude,
    required this.clockType,
  });

  Map<String, dynamic> toJson() {
    return {
      'branch_id': branchId,
      'latitude': latitude,
      'longitude': longitude,
      'clock_type': clockType,
    };
  }
}

class ClockInOutResponse {
  final bool success;
  final String message;
  final dynamic data;

  ClockInOutResponse({required this.success, required this.message, this.data});

  factory ClockInOutResponse.fromJson(Map<String, dynamic> json) {
    return ClockInOutResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}
