import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/global_service.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_model.dart';

class ApproverDashboardRepository {
  final ServerService _serverService = ServerService();

  Future<ApproverDashboardData> getApproverDashboard() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");
      final userId = pref.getString("userId");

      if (token == null || userId == null) {
        throw Exception('Authentication data not found');
      }
      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}manager/home/$userId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ApproverDashboardData.fromJson(data['data']);
        } else {
          throw Exception('Failed to fetch approver dashboard data');
        }
      } else {
        throw Exception(
          'Failed to fetch approver dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching approver dashboard data: $e');
    }
  }
}

class ApproverDashboardData {
  final ApproverUser user;
  final List<LeaveModel> myLeaveRequests;
  final List<PendingLeaveRequest> pendingLeaveNeedsApproval;
  final int pendingLeavesCount;
  final int ownLeavesCount;
  final List<LeaveBalanceModel> leaveBalances;

  ApproverDashboardData({
    required this.user,
    required this.myLeaveRequests,
    required this.pendingLeaveNeedsApproval,
    required this.pendingLeavesCount,
    required this.ownLeavesCount,
    required this.leaveBalances,
  });

  factory ApproverDashboardData.fromJson(Map<String, dynamic> json) {
    return ApproverDashboardData(
      user: ApproverUser.fromJson(json['user']),
      myLeaveRequests:
          (json['my_leave_request'] as List)
              .map((e) => LeaveModel.fromJson(e))
              .toList(),
      pendingLeaveNeedsApproval:
          (json['pending_leave_needs_approval'] as List)
              .map((e) => PendingLeaveRequest.fromJson(e))
              .toList(),
      pendingLeavesCount: json['pending_leaves_count'] ?? 0,
      ownLeavesCount: json['own_leaves_count'] ?? 0,
      leaveBalances:
          (json['leaveBalances'] as List)
              .map((e) => LeaveBalanceModel.fromJson(e))
              .toList(),
    );
  }
}

class ApproverUser {
  final String ucode;
  final String uid;
  final int ulevel;
  final String bcode;
  final String datecreate;
  final String isapprover;
  final String ustatus;
  final String exdate;
  final String uname;
  final String? profileImage;
  final String? profileImageUrl;
  final String changepassword;

  ApproverUser({
    required this.ucode,
    required this.uid,
    required this.ulevel,
    required this.bcode,
    required this.datecreate,
    required this.isapprover,
    required this.ustatus,
    required this.exdate,
    required this.uname,
    this.profileImage,
    this.profileImageUrl,
    required this.changepassword,
  });

  factory ApproverUser.fromJson(Map<String, dynamic> json) {
    return ApproverUser(
      ucode: json['ucode'] ?? '',
      uid: json['uid'] ?? '',
      ulevel: json['ulevel'] ?? 0,
      bcode: json['bcode'] ?? '',
      datecreate: json['datecreate'] ?? '',
      isapprover: json['isapprover'] ?? 'N',
      ustatus: json['ustatus'] ?? 'A',
      exdate: json['exdate'] ?? '',
      uname: json['uname'] ?? '',
      profileImage: json['profile_image'],
      profileImageUrl: json['profile_image_url'],
      changepassword: json['changepassword'] ?? 'N',
    );
  }
}

class PendingLeaveRequest {
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
  final String ltyp;
  final String requesterName;
  final String staffId;
  final String email;
  final String positionName;
  final String departmentName;
  final String branchShortName;
  final String branchFullName;

  PendingLeaveRequest({
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
    required this.ltyp,
    required this.requesterName,
    required this.staffId,
    required this.email,
    required this.positionName,
    required this.departmentName,
    required this.branchShortName,
    required this.branchFullName,
  });

  factory PendingLeaveRequest.fromJson(Map<String, dynamic> json) {
    return PendingLeaveRequest(
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
      ltyp: json['ltyp']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      positionName: json['position_name']?.toString() ?? '',
      departmentName: json['department_name']?.toString() ?? '',
      branchShortName: json['branch_short_name']?.toString() ?? '',
      branchFullName: json['branch_full_name']?.toString() ?? '',
    );
  }

  // Helper getters
  DateTime get fromDate => DateTime.tryParse(frdat) ?? DateTime.now();
  DateTime get toDate => DateTime.tryParse(todat) ?? DateTime.now();
  DateTime get requestDate => DateTime.tryParse(createdate) ?? DateTime.now();
  double get numLeaveDays => double.tryParse(numleav) ?? 0.0;
  bool get isFullDay => lfor == '1';
  bool get isPending => statu == '2';
}
