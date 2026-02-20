import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/manager_leave_history_model.dart';
import '../services/global_service.dart';

class ManagerLeaveHistoryRepository {
  Future<ManagerLeaveHistoryResponse> getManagerLeaveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http
          .get(
            Uri.parse('${ServerService().baseUrl}request-history-screens'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ManagerLeaveHistoryResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load leave history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
