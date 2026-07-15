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
  final String changepassword;
  final String? profileImage;
  final String? updatedAt;
  final String? gender;
  final String? dob;

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
    required this.changepassword,
    this.profileImage,
    this.updatedAt,
    this.gender,
    this.dob,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    ucode: json['ucode']?.toString() ?? '',
    uid: json['uid']?.toString() ?? '',
    ulevel: json['ulevel'] is int
        ? json['ulevel'] as int
        : int.tryParse(json['ulevel']?.toString() ?? '') ?? 0,
    bcode: json['bcode']?.toString() ?? '',
    datecreate: json['datecreate']?.toString() ?? '',
    isapprover: json['isapprover']?.toString() ?? 'N',
    ustatus: json['ustatus']?.toString() ?? '',
    exdate: json['exdate']?.toString() ?? '',
    uname: json['uname']?.toString() ?? '',
    changepassword: json['changepassword']?.toString() ?? 'N',
    profileImage: json['profile_image']?.toString(),
    updatedAt: json['updated_at']?.toString(),
    gender: json['gender']?.toString(),
    dob: json['dob']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'ucode': ucode,
    'uid': uid,
    'ulevel': ulevel,
    'bcode': bcode,
    'datecreate': datecreate,
    'isapprover': isapprover,
    'ustatus': ustatus,
    'exdate': exdate,
    'uname': uname,
    'changepassword': changepassword,
    'profile_image': profileImage,
    'updated_at': updatedAt,
    'gender': gender,
    'dob': dob,
  };
}
