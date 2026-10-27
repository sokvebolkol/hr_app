import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ceo_dashboard_model.dart';
import '../services/global_service.dart';

class ManagerDashboardRepository {
  final ServerService _serverService = ServerService();

  Future<CeoDashboardResponse> getAttendanceSummary({String? month}) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");
      final userId = pref.getString("userId");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Build URL with month parameter if provided
      String url = '${_serverService.baseUrl}manager/home/$userId';
      if (month != null) {
        url += '?month=$month';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data is! Map<String, dynamic>) {
            throw Exception('Invalid response format: Expected JSON object');
          }

          if (!data.containsKey('success')) {
            throw Exception(
              'Invalid response structure: Missing success field',
            );
          }

          if (!data.containsKey('data')) {
            throw Exception('Invalid response structure: Missing data field');
          }

          return CeoDashboardResponse.fromJson(data);
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ??
                'Failed to load attendance summary (${response.statusCode})',
          );
        } catch (parseError) {
          throw Exception(
            'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout: Please try again');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('Invalid response format from server');
      } else if (e.toString().contains('HandshakeException')) {
        throw Exception('SSL/TLS connection error');
      } else {
        rethrow; // This will preserve the original exception message
      }
    }
  }

}

