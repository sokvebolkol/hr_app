import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/leave_history_model.dart';
import '../services/global_service.dart';

class LeaveHistoryRepository {
  final ServerService _serverService = ServerService();

  // Get leave history data
  Future<List<LeaveHistoryModel>> getLeaveHistory() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}request-history-screens'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['leaves'] as List)
              .map((e) => LeaveHistoryModel.fromJson(e))
              .toList();
        } else {
          throw Exception('Failed to load leave history');
        }
      } else {
        throw Exception(
          'Failed to fetch leave history: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching leave history');
    }
  }
}
