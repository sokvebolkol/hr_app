import 'leave_history_model.dart';

class ManagerLeaveHistoryResponse {
  final bool success;
  final List<LeaveHistoryModel> myLeaveRequest;
  final List<StaffLeaveModel> approvedLeaves;

  ManagerLeaveHistoryResponse({
    required this.success,
    required this.myLeaveRequest,
    required this.approvedLeaves,
  });

  factory ManagerLeaveHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ManagerLeaveHistoryResponse(
      success: json['success'] ?? false,
      myLeaveRequest:
          (json['my_leave_request'] as List<dynamic>?)
              ?.map((item) => LeaveHistoryModel.fromJson(item))
              .toList() ??
          [],
      approvedLeaves:
          (json['approved_leaves'] as List<dynamic>?)
              ?.map((item) => StaffLeaveModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class StaffLeaveModel {
  final String lreid;
  final String orgid;
  final String eid;
  final String leaid;
  final String frdat;
  final String todat;
  final String numleav;
  final String lfor;
  final String lnot;
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
  final String? createdAt;
  final String? updatedAt;
  final String ltyp;
  final String requesterName;
  final String staffId;
  final String email;
  final String leaveNote;
  final String positionName;
  final String departmentName;
  final String branchShortName;
  final String branchFullName;

  StaffLeaveModel({
    required this.lreid,
    required this.orgid,
    required this.eid,
    required this.leaid,
    required this.frdat,
    required this.todat,
    required this.numleav,
    required this.lfor,
    required this.lnot,
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
    this.createdAt,
    this.updatedAt,
    required this.ltyp,
    required this.requesterName,
    required this.staffId,
    required this.email,
    required this.leaveNote,
    required this.positionName,
    required this.departmentName,
    required this.branchShortName,
    required this.branchFullName,
  });

  factory StaffLeaveModel.fromJson(Map<String, dynamic> json) {
    return StaffLeaveModel(
      lreid: json['lreid']?.toString() ?? '',
      orgid: json['orgid']?.toString() ?? '',
      eid: json['eid']?.toString() ?? '',
      leaid: json['leaid']?.toString() ?? '',
      frdat: json['frdat']?.toString() ?? '',
      todat: json['todat']?.toString() ?? '',
      numleav: json['numleav']?.toString() ?? '',
      lfor: json['lfor']?.toString() ?? '',
      lnot: json['lnot']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      file: json['file']?.toString(),
      createdate: json['createdate']?.toString() ?? '',
      statu: json['statu']?.toString() ?? '',
      holiday: json['holiday']?.toString() ?? '',
      requestedBy: json['requested_by']?.toString(),
      countAttendanceMissing: json['count_attendance_missing']?.toString(),
      adjustFromDate: json['adjust_from_date']?.toString(),
      adjustToDate: json['adjust_to_date']?.toString(),
      leaveSupportDoc: json['leave_support_doc']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      ltyp: json['ltyp']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      leaveNote: json['leave_note']?.toString() ?? '',
      positionName: json['position_name']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      branchShortName: json['branch_short_name']?.toString() ?? '',
      branchFullName: json['branch_full_name']?.toString() ?? '',
    );
  }

  // Helper getters
  DateTime get fromDate => DateTime.tryParse(frdat) ?? DateTime.now();
  DateTime get toDate => DateTime.tryParse(todat) ?? DateTime.now();
  DateTime get createdDate => DateTime.tryParse(createdate) ?? DateTime.now();

  double get numberOfDays => double.tryParse(numleav) ?? 0.0;
  bool get isFullDay => lfor == '1';
  bool get isPending => statu == '2';
  bool get isApproved => statu == '1';
  bool get isRejected => statu == '0';

  String get statusText {
    switch (statu) {
      case '1':
        return 'Approved';
      case '2':
        return 'Pending';
      case '0':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  bool get hasDocument => file != null && file!.isNotEmpty;
  String? get documentUrl => hasDocument ? file : null;

  // Convert to LeaveHistoryModel for detail screen
  LeaveHistoryModel toLeaveHistoryModel() {
    return LeaveHistoryModel(
      lreid: lreid,
      eid: eid,
      dname: requesterName,
      eCard: staffId,
      position: positionName,
      department: departmentName,
      email: email,
      branchName: branchFullName,
      frdat: frdat,
      todat: todat,
      leaid: leaid,
      ltyp: ltyp,
      numleav: numleav,
      lfor: lfor,
      statu: statu,
      reason: reason,
      leaveSupportDoc: leaveSupportDoc,
      createdate: createdate,
      leaveNote: leaveNote,
      prioList: [],
      isLeaveCanCancel: false,
      statusText: statusText,
      hasDocument: hasDocument,
      documentUrl: documentUrl,
    );
  }
}
