import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/global_service.dart';

class LeaveDetailRepository {
  final ServerService _serverService = ServerService();

  // Cancel leave request
  Future<bool> cancelLeaveRequest(String leaveId) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}leave/$leaveId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'leave_id': leaveId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to cancel leave');
      }
    } catch (e) {
      throw Exception('Error cancelling leave: $e');
    }
  }

  // Send follow-up message
  Future<bool> sendFollowUpMessage(
    String approverId,
    String leaveId,
    String message,
  ) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }
      final response = await http.post(
        Uri.parse(
          '${_serverService.baseUrl}leave/follow-up/$approverId/$leaveId',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'leave_id': leaveId, 'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to send follow-up: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending follow-up: $e');
    }
  }

  // Get available leave balance for employee
  Future<Map<String, dynamic>> getLeaveBalance(String employeeId) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse(
          '${_serverService.baseUrl}employee/$employeeId/leave-balance',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': 'Leave balance retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'data': null,
          'message': 'Failed to get leave balance: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error getting leave balance: $e',
      };
    }
  }
}
