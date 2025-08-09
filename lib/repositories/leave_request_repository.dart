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

  // Add submit leave request function
  Future<LeaveRequestResponse> submitLeaveRequest({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required int leaveFor,
    required double totalLeave,
    required List<Map<String, dynamic>> approvers,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final body = {
        "leave_type": leaveType,
        "from_date": fromDate,
        "to_date": toDate,
        "reason": reason,
        "leave_for": leaveFor,
        "total_leave": totalLeave,
        "approvers": approvers,
      };

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}request-leave'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return LeaveRequestResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['message'] ?? 'Failed to submit leave request',
        );
      }
    } catch (e) {
      throw Exception('Error submitting leave request: $e');
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

// Add response model for submit leave request
class LeaveRequestResponse {
  final bool success;
  final String message;
  final String? lreid;

  LeaveRequestResponse({
    required this.success,
    required this.message,
    this.lreid,
  });

  factory LeaveRequestResponse.fromJson(Map<String, dynamic> json) {
    return LeaveRequestResponse(
      success: json['success'],
      message: json['message'],
      lreid: json['data']?['lreid'],
    );
  }
}
