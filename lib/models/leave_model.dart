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
  final String statu;
  final String reason;
  final String createdate;
  final List<PrioModel> prioList;

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
    required this.statu,
    required this.reason,
    required this.createdate,
    required this.prioList,
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
    statu: json['statu'].toString(),
    reason: json['reason'],
    createdate: json['createdate'],
    prioList:
        (json['prio_list'] as List<dynamic>?)
            ?.map((e) => PrioModel.fromJson(e))
            .toList() ??
        [],
  );
}

class PrioModel {
  final int prio;
  final int apstatu;
  final String apstatuText;

  PrioModel({
    required this.prio,
    required this.apstatu,
    required this.apstatuText,
  });

  factory PrioModel.fromJson(Map<String, dynamic> json) => PrioModel(
    prio: json['prio'],
    apstatu: json['apstatu'],
    apstatuText: json['apstatu_text'],
  );
}
