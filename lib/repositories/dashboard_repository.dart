import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_balance_model.dart';
import '../models/leave_model.dart';
import '../models/user_model.dart';
import '../services/global_service.dart';

class DashboardRepository {
  final ServerService _serverService = ServerService();

  // Get dashboard data from API
  Future<DashboardData> getDashboardData() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final userId = pref.getString("userId");
      final token = pref.getString("token");

      if (userId == null) {
        throw Exception('User ID not found in local storage');
      }

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}home/$userId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardData(
          user: UserModel.fromJson(data['user']),
          leaves:
              (data['leaves'] as List)
                  .map((e) => LeaveModel.fromJson(e))
                  .toList(),
          leaveBalance: LeaveBalanceModel.fromJson(data['leaveBalances'][0]),
        );
      } else {
        throw Exception(
          'Failed to fetch dashboard data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching dashboard data: $e');
    }
  }

  // Get user ID from local storage
  Future<String?> getUserId() async {
    try {
      final pref = await SharedPreferences.getInstance();
      return pref.getString("userId");
    } catch (e) {
      throw Exception('Error getting user ID: $e');
    }
  }

  // Logout user (clear local data)
  Future<void> logout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.clear();
  }
}

class DashboardData {
  final UserModel user;
  final List<LeaveModel> leaves;
  final LeaveBalanceModel leaveBalance;

  DashboardData({
    required this.user,
    required this.leaves,
    required this.leaveBalance,
  });
}
