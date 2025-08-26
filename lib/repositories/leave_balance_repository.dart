import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_balance_detail_model.dart';
import '../services/global_service.dart';

class LeaveBalanceRepository {
  final ServerService _serverService = ServerService();

  // Get leave balance data for a specific year
  Future<LeaveBalanceResponse?> getLeaveBalance(int year) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}leave-balance?year=$year'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true &&
            data['data'] != null &&
            data['data'].isNotEmpty) {
          return LeaveBalanceResponse.fromJson(data);
        } else {
          throw Exception('No leave balance data found for year $year');
        }
      } else {
        throw Exception(
          'Failed to fetch leave balance: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching leave balance: $e');
    }
  }
}
