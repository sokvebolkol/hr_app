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

// Add StaffApprovalItem class for the approval workflow
class StaffApprovalItem {
  final String approverName;
  final String approverId;
  final int prio;
  final int apstatu;
  final String remark;
  final String apstatuText;
  final String prioText;

  StaffApprovalItem({
    required this.approverName,
    required this.approverId,
    required this.prio,
    required this.apstatu,
    required this.remark,
    required this.apstatuText,
    required this.prioText,
  });

  factory StaffApprovalItem.fromJson(Map<String, dynamic> json) {
    return StaffApprovalItem(
      approverName: json['approver_name'] as String? ?? '',
      approverId: json['approver_id'] as String? ?? '',
      prio: json['prio'] as int? ?? 0,
      apstatu: json['apstatu'] as int? ?? 0,
      remark: json['remark'] as String? ?? '',
      apstatuText: json['apstatu_text'] as String? ?? '',
      prioText: json['prio_text'] as String? ?? '',
    );
  }

  // Helper getters
  bool get isApproved => apstatu == 1;
  bool get isRejected => apstatu == 0;
  bool get isPending => apstatu == 2;
  bool get hasRemark => remark.trim().isNotEmpty;
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
  final String statuText;
  final List<StaffApprovalItem> prioList;

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
    required this.statuText,
    required this.prioList,
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
      statuText: json['statu_text']?.toString() ?? '',
      prioList:
          (json['prio_list'] as List<dynamic>?)
              ?.map(
                (item) =>
                    StaffApprovalItem.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
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
    if (statuText.isNotEmpty) return statuText;

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

  // Approval workflow helpers
  bool get hasApprovalWorkflow => prioList.isNotEmpty;
  List<StaffApprovalItem> get sortedApprovals {
    final sorted = [...prioList];
    sorted.sort((a, b) => a.prio.compareTo(b.prio));
    return sorted;
  }

  int get approvedCount => prioList.where((item) => item.isApproved).length;
  int get pendingCount => prioList.where((item) => item.isPending).length;
  int get rejectedCount => prioList.where((item) => item.isRejected).length;

  StaffApprovalItem? get currentPendingApprover =>
      prioList.where((item) => item.isPending).isNotEmpty
          ? prioList.where((item) => item.isPending).first
          : null;

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
      prioList:
          prioList
              .map(
                (item) => PriorityModel(
                  approverName: item.approverName,
                  approverId: item.approverId,
                  prio: item.prio,
                  apstatu: item.apstatu,
                  remark: item.remark,
                  apstatuText: item.apstatuText,
                  prioText: item.prioText,
                ),
              )
              .toList(),
      isLeaveCanCancel: false,
      statusText: statusText,
      hasDocument: hasDocument,
      documentUrl: documentUrl,
    );
  }
}
