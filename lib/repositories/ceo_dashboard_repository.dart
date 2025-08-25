import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ceo_dashboard_model.dart';
import '../services/global_service.dart';

class CeoDashboardRepository {
  final ServerService _serverService = ServerService();

  Future<CeoDashboardResponse> getAttendanceSummary({String? month}) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('CEO Dashboard - Getting attendance summary');
      if (month != null) {
        print('Filtering by month: $month');
      }

      // Build URL with month parameter if provided
      String url = '${_serverService.baseUrl}ceo/attendance-summary';
      if (month != null) {
        url += '?month=$month';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('CEO Dashboard Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data is! Map<String, dynamic>) {
            throw Exception('Invalid response format: Expected JSON object');
          }

          if (!data.containsKey('success') || !data.containsKey('data')) {
            throw Exception(
              'Invalid response structure: Missing required fields',
            );
          }

          return CeoDashboardResponse.fromJson(data);
        } catch (e) {
          print('JSON Parsing Error: $e');
          print('Raw Response: ${response.body}');
          throw Exception('Failed to parse response: $e');
        }
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ?? 'Failed to load attendance summary',
          );
        } catch (parseError) {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error in getAttendanceSummary: $e');
      if (e.toString().contains('SocketException')) {
        throw Exception('Network error: Please check your internet connection');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout: Please try again');
      } else if (e.toString().contains('FormatException')) {
        throw Exception('Invalid response format from server');
      } else {
        throw Exception('Error loading attendance summary: $e');
      }
    }
  }
}
