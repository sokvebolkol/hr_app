import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_by_department_model.dart';
import '../services/global_service.dart';

class AttendanceByDepartmentRepository {
  final ServerService _serverService = ServerService();

  Future<AttendanceByDepartmentResponse> getAttendanceByDepartment({
    String? startDate,
    String? endDate,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      if (startDate != null) print('Start Date: $startDate');
      if (endDate != null) print('End Date: $endDate');

      // Build URL with optional date parameters
      String url = '${_serverService.baseUrl}attendance-by-department';
      List<String> queryParams = [];

      if (startDate != null) {
        queryParams.add('start_date=$startDate');
      }
      if (endDate != null) {
        queryParams.add('end_date=$endDate');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Attendance By Department Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (data is! Map<String, dynamic>) {
            throw Exception('Invalid response format: Expected JSON object');
          }

          if (!data.containsKey('success') || !data.containsKey('data')) {
            throw Exception(
              'Invalid response format: Missing success or data field',
            );
          }

          return AttendanceByDepartmentResponse.fromJson(data);
        } catch (e) {
          print('Error parsing attendance by department data: $e');
          throw Exception('Failed to parse attendance data: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Failed to fetch attendance data';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error in getAttendanceByDepartment: $e');
      rethrow;
    }
  }
}
