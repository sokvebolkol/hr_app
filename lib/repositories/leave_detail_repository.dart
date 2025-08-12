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
        throw Exception('Failed to cancel leave: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error cancelling leave: $e');
    }
  }

  // Update leave request
  Future<bool> updateLeaveRequest({
    required String leaveId,
    required String fromDate,
    required String toDate,
    required String reason,
    required String leaveType,
    required String numDays,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.put(
        Uri.parse('${_serverService.baseUrl}update-leave'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'leave_id': leaveId,
          'from_date': fromDate,
          'to_date': toDate,
          'reason': reason,
          'leave_type': leaveType,
          'num_days': numDays,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to update leave: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating leave: $e');
    }
  }

  // Send follow-up message
  Future<bool> sendFollowUpMessage(String leaveId, String message) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}follow-up-leave'),
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
}
