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
    id: json['id'] ?? 0,
    orgId: json['org_id']?.toString() ?? '',
    employeeId: json['employee_id']?.toString() ?? '',
    year: json['year'] ?? 0,
    annualLeaveForwardBalance:
        json['annual_leave_forward_balance']?.toString() ?? '0',
    annualLeaveEntitlement: json['annual_leave_entitlement']?.toString() ?? '0',
    annualLeaveUsed: json['annual_leave_used']?.toString() ?? '0',
    annualLeaveBalance: json['annual_leave_balance']?.toString() ?? '0',
    sickLeaveEntitlement: json['sick_leave_entitlement']?.toString() ?? '0',
    sickLeaveUsed: json['sick_leave_used']?.toString() ?? '0',
    sickLeaveBalance: json['sick_leave_balance']?.toString() ?? '0',
    specialLeaveEntitlement:
        json['special_leave_entitlement']?.toString() ?? '0',
    specialLeaveUsed: json['special_leave_used']?.toString() ?? '0',
    specialLeaveBalance: json['special_leave_balance']?.toString() ?? '0',
    maternityLeaveEntitlement:
        json['maternity_leave_entitlement']?.toString() ?? '0',
    maternityLeaveUsed: json['maternity_leave_used']?.toString() ?? '0',
    maternityLeaveBalance: json['maternity_leave_balance']?.toString() ?? '0',
    unpaidLeaveUsed: json['unpaid_leave_used']?.toString() ?? '0',
    approvedLeaveRequest: json['approved_leave_request']?.toString() ?? '0',
    pendingLeaveRequest: json['pending_leave_request']?.toString() ?? '0',
    rejectedLeaveRequest: json['rejected_leave_request']?.toString() ?? '0',
    remark: json['remark']?.toString() ?? '',
  );
}
