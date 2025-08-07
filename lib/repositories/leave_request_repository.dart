import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_type_model.dart';
import '../models/approver_model.dart';
import '../services/global_service.dart';

class LeaveRequestRepository {
  final ServerService _serverService = ServerService();

  Future<LeaveRequestData> getLeaveRequestData() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}leave-request-screen'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return LeaveRequestData(
          leaveTypes:
              (data['leaveTypes'] as List)
                  .map((e) => LeaveTypeModel.fromJson(e))
                  .toList(),
          approvers:
              (data['approvers'] as List)
                  .map((e) => ApproverModel.fromJson(e))
                  .toList(),
          holidays: List<String>.from(data['holidays']),
          userId: data['userId'],
        );
      } else {
        throw Exception(
          'Failed to fetch leave request data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching leave request data: $e');
    }
  }
}

class LeaveRequestData {
  final List<LeaveTypeModel> leaveTypes;
  final List<ApproverModel> approvers;
  final List<String> holidays;
  final String userId;

  LeaveRequestData({
    required this.leaveTypes,
    required this.approvers,
    required this.holidays,
    required this.userId,
  });
}
