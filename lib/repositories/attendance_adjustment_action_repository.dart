import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/global_service.dart';

class AttendanceAdjustmentActionRepository {
  final ServerService _serverService = ServerService();

  Future<Map<String, dynamic>> approveAttendanceAdjustment({
    required String adjustmentId,
    String? remark,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");
      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final body = json.encode({'remark': remark ?? ''});

      final response = await http.post(
        Uri.parse(
          '${_serverService.baseUrl}attendance/adjustment/$adjustmentId/approve',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Attendance adjustment approved successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['error'] ??
              'Failed to approve attendance adjustment',
          'error': responseData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> rejectAttendanceAdjustment({
    required String adjustmentId,
    String? remark,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }
      final body = json.encode({'remark': remark ?? ''});
      final response = await http.post(
        Uri.parse(
          '${_serverService.baseUrl}attendance/adjustment/$adjustmentId/reject',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Attendance adjustment rejected successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Failed to reject attendance adjustment',
          'error': responseData['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }
}
