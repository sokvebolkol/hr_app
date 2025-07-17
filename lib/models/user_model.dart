class UserModel {
  final String ucode;
  final String uid;
  final int ulevel;
  final String bcode;
  final String datecreate;
  final String isapprover;
  final String ustatus;
  final String exdate;
  final String uname;
  final String? u1;
  final String? u2;
  final String? u3;
  final String? u4;
  final String? u5;
  final String changepassword;

  UserModel({
    required this.ucode,
    required this.uid,
    required this.ulevel,
    required this.bcode,
    required this.datecreate,
    required this.isapprover,
    required this.ustatus,
    required this.exdate,
    required this.uname,
    this.u1,
    this.u2,
    this.u3,
    this.u4,
    this.u5,
    required this.changepassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    ucode: json['ucode'],
    uid: json['uid'],
    ulevel: json['ulevel'],
    bcode: json['bcode'],
    datecreate: json['datecreate'],
    isapprover: json['isapprover'],
    ustatus: json['ustatus'],
    exdate: json['exdate'],
    uname: json['uname'],
    u1: json['u1'],
    u2: json['u2'],
    u3: json['u3'],
    u4: json['u4'],
    u5: json['u5'],
    changepassword: json['changepassword'],
  );
}
