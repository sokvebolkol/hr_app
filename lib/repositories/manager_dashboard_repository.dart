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

      print('Manager Dashboard - Getting attendance summary for user: $userId');
      if (month != null) {
        print('Filtering by month: $month');
      }

      // Build URL with month parameter if provided
      String url = '${_serverService.baseUrl}manager/home/$userId';
      if (month != null) {
        url += '?month=$month';
      }

      print('Manager Dashboard - Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Manager Dashboard - Response status: ${response.statusCode}');
      print('Manager Dashboard - Response body: ${response.body}');
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Manager Dashboard - Parsed data: $data');

          if (data is! Map<String, dynamic>) {
            print('Manager Dashboard - Error: Invalid response format');
            throw Exception('Invalid response format: Expected JSON object');
          }

          if (!data.containsKey('success')) {
            print('Manager Dashboard - Error: Missing success field');
            throw Exception(
              'Invalid response structure: Missing success field',
            );
          }

          if (!data.containsKey('data')) {
            print('Manager Dashboard - Error: Missing data field');
            throw Exception('Invalid response structure: Missing data field');
          }

          print('Manager Dashboard - Creating response from JSON...');
          print('Manager Dashboard - Data keys: ${data.keys}');
          print('Manager Dashboard - Data["data"] keys: ${data["data"]?.keys}');
          print(
            'Manager Dashboard - Data["data"]["summary"] keys: ${data["data"]?["summary"]?.keys}',
          );

          return CeoDashboardResponse.fromJson(data);
        } catch (e) {
          print('Manager Dashboard - Parse error: $e');
          throw Exception('Failed to parse response: $e');
        }
      } else {
        print('Manager Dashboard - HTTP Error: ${response.statusCode}');
        try {
          final errorData = json.decode(response.body);
          print('Manager Dashboard - Error response: $errorData');
          throw Exception(
            errorData['message'] ??
                'Failed to load attendance summary (${response.statusCode})',
          );
        } catch (parseError) {
          print(
            'Manager Dashboard - Error parsing error response: $parseError',
          );
          throw Exception(
            'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Manager Dashboard - Catch block error: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout: Please try again');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('Invalid response format from server');
      } else if (e.toString().contains('HandshakeException')) {
        throw Exception('SSL/TLS connection error');
      } else {
        print('Manager Dashboard - Rethrowing error: $e');
        rethrow; // This will preserve the original exception message
      }
    }
  }
}
