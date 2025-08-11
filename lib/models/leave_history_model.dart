class LeaveHistoryModel {
  final String eid;
  final String dname;
  final String lreid;
  final String frdat;
  final String todat;
  final String leaid;
  final String ltyp;
  final String numleav;
  final String lfor;
  final String statu;
  final String reason;
  final String createdate;
  final List<PriorityModel> prioList;
  final String statusText;

  LeaveHistoryModel({
    required this.eid,
    required this.dname,
    required this.lreid,
    required this.frdat,
    required this.todat,
    required this.leaid,
    required this.ltyp,
    required this.numleav,
    required this.lfor,
    required this.statu,
    required this.reason,
    required this.createdate,
    required this.prioList,
    required this.statusText,
  });

  factory LeaveHistoryModel.fromJson(Map<String, dynamic> json) {
    return LeaveHistoryModel(
      eid: json['eid'],
      dname: json['dname'],
      lreid: json['lreid'],
      frdat: json['frdat'],
      todat: json['todat'],
      leaid: json['leaid'],
      ltyp: json['ltyp'],
      numleav: json['numleav'],
      lfor: json['lfor'],
      statu: json['statu'],
      reason: json['reason'],
      createdate: json['createdate'],
      prioList:
          (json['prio_list'] as List)
              .map((e) => PriorityModel.fromJson(e))
              .toList(),
      statusText: json['statu_text'],
    );
  }

  // Helper getters
  bool get isFullDay => lfor == '1';
  bool get isPending => statu == '2';
  bool get isApproved => statu == '1';
  bool get isRejected => statu == '0';
  bool get isCancelled => statu == '3';

  double get numberOfDays => double.tryParse(numleav) ?? 0;

  DateTime get fromDate => DateTime.parse(frdat);
  DateTime get toDate => DateTime.parse(todat);
  DateTime get createdDate => DateTime.parse(createdate);
}

class PriorityModel {
  final String approverName;
  final String? userApproverToken;
  final int prio;
  final int apstatu;
  final String apstatuText;
  final String prioText;

  PriorityModel({
    required this.approverName,
    this.userApproverToken,
    required this.prio,
    required this.apstatu,
    required this.apstatuText,
    required this.prioText,
  });

  factory PriorityModel.fromJson(Map<String, dynamic> json) {
    return PriorityModel(
      approverName: json['approver_name'],
      userApproverToken: json['user_approver_token'],
      prio: json['prio'],
      apstatu: json['apstatu'],
      apstatuText: json['apstatu_text'],
      prioText: json['prio_text'],
    );
  }

  // Helper getters
  bool get isPending => apstatu == 2;
  bool get isApproved => apstatu == 1;
  bool get isRejected => apstatu == 0;
}

class LeaveHistoryResponse {
  final bool success;
  final List<LeaveHistoryModel> data;

  LeaveHistoryResponse({required this.success, required this.data});

  factory LeaveHistoryResponse.fromJson(Map<String, dynamic> json) {
    return LeaveHistoryResponse(
      success: json['success'] ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((item) => LeaveHistoryModel.fromJson(item))
              .toList() ??
          [],
    );
  }
}
