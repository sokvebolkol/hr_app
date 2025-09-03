import 'leave_history_model.dart';

class LeaveModel {
  final String eid;
  final String dname;
  final String lreid;
  final String frdat;
  final String todat;
  final String leaid;
  final String ltyp;
  final String numleav;
  final String lfor;
  final String leaveNote;
  final bool isLeaveCanCancel;
  final String statu;
  final String reason;
  final String createdate;
  final List<PrioModel> prioList;
  final String statuText;

  LeaveModel({
    required this.eid,
    required this.dname,
    required this.lreid,
    required this.frdat,
    required this.todat,
    required this.leaid,
    required this.ltyp,
    required this.numleav,
    required this.lfor,
    required this.leaveNote,
    required this.isLeaveCanCancel,
    required this.statu,
    required this.reason,
    required this.createdate,
    required this.prioList,
    required this.statuText,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) => LeaveModel(
    eid: json['eid'],
    dname: json['dname'],
    lreid: json['lreid'],
    frdat: json['frdat'],
    todat: json['todat'],
    leaid: json['leaid'],
    ltyp: json['ltyp'],
    numleav: json['numleav'].toString(),
    lfor: json['lfor'].toString(),
    leaveNote: json['leave_note'],
    isLeaveCanCancel: json['isLeaveCanCancel'] ?? false,
    statu: json['statu'].toString(),
    reason: json['reason'],
    createdate: json['createdate'],
    prioList:
        (json['prio_list'] as List<dynamic>?)
            ?.map((e) => PrioModel.fromJson(e))
            .toList() ??
        [],
    statuText: json['statu_text'] ?? '',
  );
}

class PrioModel {
  final String? approverName;
  final String? userApproverToken;
  final int prio;
  final int apstatu;
  final String apstatuText;
  final String priText;
  final String? remark;

  PrioModel({
    this.approverName,
    this.userApproverToken,
    required this.prio,
    required this.apstatu,
    required this.apstatuText,
    required this.priText,
    this.remark,
  });

  factory PrioModel.fromJson(Map<String, dynamic> json) => PrioModel(
    approverName: json['approver_name'],
    userApproverToken: json['user_approver_token'],
    prio: json['prio'],
    apstatu: json['apstatu'],
    apstatuText: json['apstatu_text'],
    priText: json['prio_text'] ?? '',
    remark: json['remark'],
  );
}

// Updated extension method with proper conversion
extension LeaveModelExtension on LeaveModel {
  LeaveHistoryModel toLeaveHistoryModel() {
    return LeaveHistoryModel(
      eid: eid,
      dname: dname,
      eCard: null,
      position: null,
      department: null,
      email: null,
      branchName: null,
      lreid: lreid,
      frdat: frdat,
      todat: todat,
      leaid: leaid,
      ltyp: ltyp,
      numleav: numleav,
      lfor: lfor,
      leaveNote: leaveNote,
      isLeaveCanCancel: isLeaveCanCancel,
      statu: statu,
      reason: reason,
      createdate: createdate,
      prioList:
          prioList
              .map(
                (prioModel) => PriorityModel(
                  approverName:
                      prioModel.approverName ??
                      'Unknown', // Provide default if null
                  userApproverToken: prioModel.userApproverToken,
                  prio: prioModel.prio,
                  apstatu: prioModel.apstatu,
                  apstatuText: prioModel.apstatuText,
                  prioText: prioModel.priText,
                  remark: prioModel.remark,
                ),
              )
              .toList(),
      statusText: statuText,
    );
  }
}
