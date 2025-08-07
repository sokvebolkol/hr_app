class LeaveTypeModel {
  final String leaid;
  final String ltyp;
  final String num;
  final String? fileSupport;
  final String? fileUrl;

  LeaveTypeModel({
    required this.leaid,
    required this.ltyp,
    required this.num,
    this.fileSupport,
    this.fileUrl,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      leaid: json['leaid'],
      ltyp: json['ltyp'],
      num: json['num'],
      fileSupport: json['file_support'],
      fileUrl: json['file_url'],
    );
  }

  bool get requiresDocument => fileSupport != null && fileUrl != null;
}
