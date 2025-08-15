import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_model.dart';
import '../services/global_service.dart';

class AttendanceRepository {
  final ServerService _serverService = ServerService();

  Future<AttendanceClockData> getAttendanceClockData() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}attendance-log-info'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Attendance Clock Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AttendanceClockData.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to load attendance data');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAttendanceClockData: $e');
      throw Exception('Error loading attendance data: $e');
    }
  }

  Future<ClockInOutResponse> clockInOut(ClockInOutRequest request) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('Clock In/Out Request: ${request.toJson()}');

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}clock-in-out'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      print('Clock In/Out Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClockInOutResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Clock in/out failed');
      }
    } catch (e) {
      print('Error in clockInOut: $e');
      throw Exception('Error during clock in/out: $e');
    }
  }
}
