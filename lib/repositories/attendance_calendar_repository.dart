import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_calendar_model.dart';
import '../services/global_service.dart';

class AttendanceCalendarRepository {
  final ServerService _serverService = ServerService();

  Future<AttendanceCalendarResponse> getAttendanceCalendar(
    AttendanceCalendarRequest request,
  ) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      print('Attendance Calendar Request: ${request.toJson()}');

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}attendance/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      print('Attendance Calendar Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AttendanceCalendarResponse.fromJson(data);
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ?? 'Failed to load attendance calendar',
          );
        } catch (_) {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error loading attendance calendar');
    }
  }
}
