class CeoDashboardResponse {
  final bool success;
  final CeoDashboardData data;

  CeoDashboardResponse({required this.success, required this.data});

  factory CeoDashboardResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('CeoDashboardResponse.fromJson - Input JSON keys: ${json.keys}');
      print('CeoDashboardResponse.fromJson - success: ${json['success']}');

      return CeoDashboardResponse(
        success: json['success'] ?? false,
        data: CeoDashboardData.fromJson(json['data']),
      );
    } catch (e) {
      print('CeoDashboardResponse.fromJson - Error: $e');
      rethrow;
    }
  }
}

class CeoDashboardData {
  final AttendanceSummary summary;

  CeoDashboardData({required this.summary});

  factory CeoDashboardData.fromJson(Map<String, dynamic> json) {
    try {
      print('CeoDashboardData.fromJson - Input JSON keys: ${json.keys}');
      print(
        'CeoDashboardData.fromJson - summary type: ${json['summary'].runtimeType}',
      );

      return CeoDashboardData(
        summary: AttendanceSummary.fromJson(json['summary']),
      );
    } catch (e) {
      print('CeoDashboardData.fromJson - Error: $e');
      rethrow;
    }
  }
}

class AttendanceSummary {
  final String date;
  final bool isWeekend;
  final bool isHoliday;
  final int totalStaff;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final int todayStaffLeaves;
  final int pendingLeavesCount;
  final int pendingAttendanceCount;
  final int approvedLeavesCount;
  final int rejectedLeavesCount;
  final List<LeaveRequest> leaveNeedToApprove;
  final List<LeaveRequest> approvedLeaves;
  final List<LeaveRequest> rejectedLeaves;
  final List<AttendanceAdjustmentRequest> pendingAttendanceNeedToApprove;

  AttendanceSummary({
    required this.date,
    required this.isWeekend,
    required this.isHoliday,
    required this.totalStaff,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.todayStaffLeaves,
    required this.pendingLeavesCount,
    required this.pendingAttendanceCount,
    required this.approvedLeavesCount,
    required this.rejectedLeavesCount,
    required this.leaveNeedToApprove,
    required this.approvedLeaves,
    required this.rejectedLeaves,
    required this.pendingAttendanceNeedToApprove,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    try {
      final attendanceList =
          (json['pending_attendance_need_to_approve'] as List? ?? []);
      return AttendanceSummary(
        date: json['date']?.toString() ?? '',
        isWeekend: json['is_weekend'] ?? false,
        isHoliday: json['is_holiday'] ?? false,
        totalStaff: _parseToInt(json['total_staff']),
        presentCount: _parseToInt(json['present_count']),
        lateCount: _parseToInt(json['late_count']),
        absentCount: _parseToInt(json['absent_count']),
        todayStaffLeaves: _parseToInt(json['today_staff_leaves']),
        pendingLeavesCount: _parseToInt(json['pending_leaves_count']),
        pendingAttendanceCount: _parseToInt(
          json['pending_attendance_count'] ?? attendanceList.length,
        ),
        approvedLeavesCount: _parseToInt(json['approved_leaves_count']),
        rejectedLeavesCount: _parseToInt(json['rejected_leaves_count']),
        leaveNeedToApprove:
            (json['leave_need_to_approve'] as List? ?? [])
                .map((e) => LeaveRequest.fromJson(e))
                .toList(),
        approvedLeaves:
            (json['approved_leaves'] as List? ?? [])
                .map((e) => LeaveRequest.fromJson(e))
                .toList(),
        rejectedLeaves:
            (json['rejected_leaves'] as List? ?? [])
                .map((e) => LeaveRequest.fromJson(e))
                .toList(),
        pendingAttendanceNeedToApprove:
            attendanceList
                .map((e) => AttendanceAdjustmentRequest.fromJson(e))
                .toList(),
      );
    } catch (e) {
      print('AttendanceSummary.fromJson - Error: $e');
      rethrow;
    }
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double get attendanceRate =>
      totalStaff > 0 ? ((presentCount + lateCount) / totalStaff) * 100 : 0;

  int get totalPendingApprovals => pendingLeavesCount + pendingAttendanceCount;
}

// Add ApprovalItem class for CEO dashboard
class CeoApprovalItem {
  final String approverName;
  final int prio;
  final int apstatu;
  final String remark;
  final String apstatuText;
  final String prioText;

  CeoApprovalItem({
    required this.approverName,
    required this.prio,
    required this.apstatu,
    required this.remark,
    required this.apstatuText,
    required this.prioText,
  });

  factory CeoApprovalItem.fromJson(Map<String, dynamic> json) {
    return CeoApprovalItem(
      approverName: json['approver_name'] as String? ?? '',
      prio: json['prio'] as int? ?? 0,
      apstatu: json['apstatu'] as int? ?? 0,
      remark: json['remark'] as String? ?? '',
      apstatuText: json['apstatu_text'] as String? ?? '',
      prioText: json['prio_text'] as String? ?? '',
    );
  }
}

class LeaveRequest {
  final String lreid;
  final String orgid;
  final String eid;
  final String staff_id;
  final String email;
  final String position;
  final String department;
  final String branch;
  final String leaid;
  final String frdat;
  final String todat;
  final String numleav;
  final String lfor;
  final String lnot;
  final String leaveNote;
  final String reason;
  final String remark;
  final String? file;
  final String createdate;
  final String statu;
  final String holiday;
  final String? requestedBy;
  final String? countAttendanceMissing;
  final String? adjustFromDate;
  final String? adjustToDate;
  final String? leaveSupportDoc;
  final String? requesterProfileImage;
  final String? updatedAt;
  final String? createdAt;
  final String ltyp;
  final String requesterName;
  final String statuText;
  final List<CeoApprovalItem> prioList;

  LeaveRequest({
    required this.lreid,
    required this.orgid,
    required this.eid,
    required this.staff_id,
    required this.email,
    required this.position,
    required this.department,
    required this.branch,
    required this.leaid,
    required this.frdat,
    required this.todat,
    required this.numleav,
    required this.lfor,
    required this.lnot,
    required this.leaveNote,
    required this.reason,
    required this.remark,
    this.file,
    required this.createdate,
    required this.statu,
    required this.holiday,
    this.requestedBy,
    this.countAttendanceMissing,
    this.adjustFromDate,
    this.adjustToDate,
    this.leaveSupportDoc,
    this.requesterProfileImage,
    this.updatedAt,
    this.createdAt,
    required this.ltyp,
    required this.requesterName,
    required this.statuText,
    required this.prioList,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      lreid: json['lreid']?.toString() ?? '',
      orgid: json['orgid']?.toString() ?? '',
      eid: json['eid']?.toString() ?? '',
      staff_id: json['staff_id']?.toString() ?? '',
      email: json['email']?.toString() ?? 'N/A',
      position: json['position_name']?.toString() ?? 'N/A',
      department: json['department_name']?.toString() ?? 'N/A',
      branch: json['branch_full_name']?.toString() ?? 'N/A',
      leaid: json['leaid']?.toString() ?? '',
      frdat: json['frdat']?.toString() ?? '',
      todat: json['todat']?.toString() ?? '',
      numleav: json['numleav']?.toString() ?? '0',
      lfor: json['lfor']?.toString() ?? '0',
      lnot: json['lnot']?.toString() ?? '0',
      leaveNote: json['leave_note'] ?? '',
      reason: json['reason']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      file: json['document_url']?.toString(),
      createdate: json['createdate']?.toString() ?? '',
      statu: json['statu']?.toString() ?? '',
      holiday: json['holiday']?.toString() ?? '0',
      requestedBy: json['requested_by']?.toString(),
      countAttendanceMissing: json['count_attendance_missing']?.toString(),
      adjustFromDate: json['adjust_from_date']?.toString(),
      adjustToDate: json['adjust_to_date']?.toString(),
      leaveSupportDoc: json['document_url']?.toString(),
      requesterProfileImage: json['profile_image_url']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      ltyp: json['ltyp']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? '',
      statuText: json['statu_text']?.toString() ?? '',
      prioList:
          (json['prio_list'] as List<dynamic>?)
              ?.map(
                (item) =>
                    CeoApprovalItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  DateTime get fromDate => DateTime.tryParse(frdat) ?? DateTime.now();
  DateTime get toDate => DateTime.tryParse(todat) ?? DateTime.now();
  DateTime get requestDate => DateTime.tryParse(createdate) ?? DateTime.now();
  double get numLeaveDays => double.tryParse(numleav) ?? 0.0;
  bool get isHalfDay => numLeaveDays == 0.5;
  bool get isFullDay => numLeaveDays >= 1.0;
  String get statusText {
    switch (statu) {
      case '0':
        return 'Rejected';
      case '1':
        return 'Approved';
      case '2':
        return 'Pending';
      case '3':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}

class AttendanceApproverItem {
  final String approverName;
  final int priority;
  final int approvalStatus;
  final String? remark;
  final String approvalStatusText;
  final String priorityText;

  AttendanceApproverItem({
    required this.approverName,
    required this.priority,
    required this.approvalStatus,
    this.remark,
    required this.approvalStatusText,
    required this.priorityText,
  });

  factory AttendanceApproverItem.fromJson(Map<String, dynamic> json) {
    return AttendanceApproverItem(
      approverName: json['approver_name'] as String? ?? '',
      priority: json['priority'] as int? ?? 0,
      approvalStatus: json['approval_status'] as int? ?? 0,
      remark: json['remark'] as String?,
      approvalStatusText: json['approval_status_text'] as String? ?? '',
      priorityText: json['priority_text'] as String? ?? '',
    );
  }
}

class AttendanceAdjustmentRequest {
  final int id;
  final String staffId;
  final String adjustType;
  final String adjustDatetime;
  final String reason;
  final int status;
  final String? adjustmentSupportDoc;
  final String createdBy;
  final String createdAt;
  final String requesterName;
  final String ecard;
  final String email;
  final String? profileImage;
  final String positionName;
  final String departmentName;
  final String branchShortName;
  final String branchFullName;
  final List<AttendanceApproverItem> approverList;
  final String statusText;
  final String adjustTypeText;
  final bool hasDocument;
  final String? documentUrl;
  final String? profileImageUrl;

  AttendanceAdjustmentRequest({
    required this.id,
    required this.staffId,
    required this.adjustType,
    required this.adjustDatetime,
    required this.reason,
    required this.status,
    this.adjustmentSupportDoc,
    required this.createdBy,
    required this.createdAt,
    required this.requesterName,
    required this.ecard,
    required this.email,
    this.profileImage,
    required this.positionName,
    required this.departmentName,
    required this.branchShortName,
    required this.branchFullName,
    required this.approverList,
    required this.statusText,
    required this.adjustTypeText,
    required this.hasDocument,
    this.documentUrl,
    this.profileImageUrl,
  });

  factory AttendanceAdjustmentRequest.fromJson(Map<String, dynamic> json) {
    return AttendanceAdjustmentRequest(
      id: json['id'] as int? ?? 0,
      staffId: json['staff_id']?.toString() ?? '',
      adjustType: json['adjust_type']?.toString() ?? '',
      adjustDatetime: json['adjust_datetime']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status'] as int? ?? 0,
      adjustmentSupportDoc: json['adjustment_support_doc']?.toString(),
      createdBy: json['created_by']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? '',
      ecard: json['ecard']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profile_image']?.toString(),
      positionName: json['position_name']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      branchShortName: json['branch_short_name']?.toString() ?? '',
      branchFullName: json['branch_full_name']?.toString() ?? '',
      approverList:
          (json['approver_list'] as List<dynamic>?)
              ?.map(
                (item) => AttendanceApproverItem.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      statusText: json['status_text']?.toString() ?? '',
      adjustTypeText: json['adjust_type_text']?.toString() ?? '',
      hasDocument: json['has_document'] as bool? ?? false,
      documentUrl: json['document_url']?.toString(),
      profileImageUrl: json['profile_image_url']?.toString(),
    );
  }

  DateTime get adjustDate =>
      DateTime.tryParse(adjustDatetime) ?? DateTime.now();
  DateTime get requestDate => DateTime.tryParse(createdAt) ?? DateTime.now();
  bool get isPending => status == 2;
}
