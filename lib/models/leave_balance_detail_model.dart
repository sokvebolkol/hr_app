import 'leave_balance_model.dart';

class LeaveBalanceResponse {
  final bool success;
  final List<LeaveBalanceModel> data;
  final String year;
  final String joinDate;

  LeaveBalanceResponse({
    required this.success,
    required this.data,
    required this.year,
    required this.joinDate,
  });

  factory LeaveBalanceResponse.fromJson(Map<String, dynamic> json) {
    final dataList =
        (json['data'] as List)
            .map((item) => LeaveBalanceModel.fromJson(item))
            .toList();

    return LeaveBalanceResponse(
      success: json['success'],
      data: dataList,
      year: json['year'].toString(),
      joinDate: json['join_date'].toString(),
    );
  }
}
