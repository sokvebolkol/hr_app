import 'leave_balance_model.dart';
import 'leave_history_model.dart';

class LeaveBalanceResponse {
  final bool success;
  final bool isViewMaternityLeave;
  final List<LeaveBalanceModel> data;
  final List<LeaveHistoryModel> approvedLeaveRequest;
  final String year;
  final String joinDate;

  LeaveBalanceResponse({
    required this.success,
    required this.isViewMaternityLeave,
    required this.data,
    required this.approvedLeaveRequest,
    required this.year,
    required this.joinDate,
  });

  factory LeaveBalanceResponse.fromJson(Map<String, dynamic> json) {
    final dataList =
        (json['leave_balances'] as List? ?? [])
            .map((item) => LeaveBalanceModel.fromJson(item))
            .toList();

    final approvedList =
        (json['approved_leave_request'] as List? ?? [])
            .map((item) => LeaveHistoryModel.fromJson(item))
            .toList();

    final isViewMaternityLeave = json['is_view_maternity_leave'] ?? false;

    return LeaveBalanceResponse(
      success: json['success'] ?? false,
      isViewMaternityLeave: isViewMaternityLeave,
      data: dataList,
      approvedLeaveRequest: approvedList,
      year: json['year']?.toString() ?? '',
      joinDate: json['join_date']?.toString() ?? '',
    );
  }
}
