class LeaveBalanceModel {
  final int id;
  final String orgId;
  final String employeeId;
  final int year;
  final String annualLeaveForwardBalance;
  final String annualLeaveEntitlement;
  final String annualLeaveUsed;
  final String annualLeaveBalance;
  final String sickLeaveEntitlement;
  final String sickLeaveUsed;
  final String sickLeaveBalance;
  final String specialLeaveEntitlement;
  final String specialLeaveUsed;
  final String specialLeaveBalance;
  final String maternityLeaveEntitlement;
  final String maternityLeaveUsed;
  final String maternityLeaveBalance;
  final String unpaidLeaveUsed;
  final String approvedLeaveRequest;
  final String pendingLeaveRequest;
  final String rejectedLeaveRequest;
  final String remark;

  LeaveBalanceModel({
    required this.id,
    required this.orgId,
    required this.employeeId,
    required this.year,
    required this.annualLeaveForwardBalance,
    required this.annualLeaveEntitlement,
    required this.annualLeaveUsed,
    required this.annualLeaveBalance,
    required this.sickLeaveEntitlement,
    required this.sickLeaveUsed,
    required this.sickLeaveBalance,
    required this.specialLeaveEntitlement,
    required this.specialLeaveUsed,
    required this.specialLeaveBalance,
    required this.maternityLeaveEntitlement,
    required this.maternityLeaveUsed,
    required this.maternityLeaveBalance,
    required this.unpaidLeaveUsed,
    required this.approvedLeaveRequest,
    required this.pendingLeaveRequest,
    required this.rejectedLeaveRequest,
    required this.remark,
  });

  factory LeaveBalanceModel.fromJson(
    Map<String, dynamic> json,
  ) => LeaveBalanceModel(
    id: json['id'],
    orgId: json['org_id'],
    employeeId: json['employee_id'],
    year: json['year'],
    annualLeaveForwardBalance: json['annual_leave_forward_balance'].toString(),
    annualLeaveEntitlement: json['annual_leave_entitlement'].toString(),
    annualLeaveUsed: json['annual_leave_used'].toString(),
    annualLeaveBalance: json['annual_leave_balance'].toString(),
    sickLeaveEntitlement: json['sick_leave_entitlement'].toString(),
    sickLeaveUsed: json['sick_leave_used'].toString(),
    sickLeaveBalance: json['sick_leave_balance'].toString(),
    specialLeaveEntitlement: json['special_leave_entitlement'].toString(),
    specialLeaveUsed: json['special_leave_used'].toString(),
    specialLeaveBalance: json['special_leave_balance'].toString(),
    maternityLeaveEntitlement: json['maternity_leave_entitlement'].toString(),
    maternityLeaveUsed: json['maternity_leave_used'].toString(),
    maternityLeaveBalance: json['maternity_leave_balance'].toString(),
    unpaidLeaveUsed: json['unpaid_leave_used'].toString(),
    approvedLeaveRequest: json['approved_leave_request'].toString(),
    pendingLeaveRequest: json['pending_leave_request'].toString(),
    rejectedLeaveRequest: json['rejected_leave_request'].toString(),
    remark: json['remark'] ?? "",
  );
}
