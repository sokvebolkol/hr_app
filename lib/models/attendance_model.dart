class AttendanceLog {
  final String timeId;
  final String empId;
  final String branchCode;
  final DateTime timeDate;
  final String timeClock;
  final String deviceName;
  final String status;
  final UserProfileInfo ? userInfoProfile;

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
      timeDate: DateTime.parse(json['tdate'] ?? DateTime.now().toIso8601String()),
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
    List<AttendanceLog> attendanceLogsList = logs.map((i) => AttendanceLog.fromJson(i)).toList();

    return AttendanceResponse(
      totalList: json['totalList'] ?? 0,
      lastStatus: json['lastStatus'] ?? '',
      attendanceLogs: attendanceLogsList,
    );
  }
}


