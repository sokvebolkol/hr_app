import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
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
      throw Exception('Error loading attendance data');
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
        Uri.parse('${_serverService.baseUrl}attendance/clock'),
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
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Clock in/out failed');
        } catch (_) {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error in clockInOut: $e');
      throw Exception('Error during clock in/out: $e');
    }
  }

  Future<Map<String, dynamic>> getAttendanceForAdjustment() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final requestBody = {"is_request_adjustment_att_screen": true};
      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}attendance/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            errorData['message'] ?? 'Failed to load attendance data',
          );
        } catch (_) {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error loading attendance data: $e');
    }
  }

  Future<Map<String, dynamic>> submitAdjustmentRequest({
    required String dateScan,
    required String adjustType,
    required String reason,
    required List<Map<String, int>> approvers,
    XFile? attachmentImage,
  }) async {
    print('Submitting adjustment request with data:');
    print('Date Scan: $dateScan');
    print('Adjust Type: $adjustType');
    print('Reason: $reason');
    print('Approvers: $approvers');
    if (attachmentImage != null) {
      print('Attachment Image: ${attachmentImage.path}');
    }
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Use multipart request if there's an image attachment
      if (attachmentImage != null) {
        return await _submitWithAttachment(
          dateScan: dateScan,
          adjustType: adjustType,
          reason: reason,
          approvers: approvers,
          attachmentImage: attachmentImage,
          token: token,
        );
      } else {
        return await _submitWithoutAttachment(
          dateScan: dateScan,
          adjustType: adjustType,
          reason: reason,
          approvers: approvers,
          token: token,
        );
      }
    } catch (e) {
      print('Error in submitAdjustmentRequest: $e');
      throw Exception('Error submitting adjustment request: $e');
    }
  }

  Future<Map<String, dynamic>> _submitWithAttachment({
    required String dateScan,
    required String adjustType,
    required String reason,
    required List<Map<String, int>> approvers,
    required XFile attachmentImage,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_serverService.baseUrl}attendance/submit-adjustment'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields.addAll({
        'date_scan': dateScan,
        'adjust_type': adjustType,
        'reason': reason,
      });

      // Add approvers in indexed format: approvers[0][approver_id], approvers[0][priority], etc.
      for (int i = 0; i < approvers.length; i++) {
        request.fields['approvers[$i][approver_id]'] =
            approvers[i]['approver_id'].toString();
        request.fields['approvers[$i][priority]'] =
            approvers[i]['priority'].toString();
      }

      // Add attachment file
      final file = File(attachmentImage.path);
      if (await file.exists()) {
        try {
          final multipartFile = await http.MultipartFile.fromPath(
            'file',
            file.path,
          );
          request.files.add(multipartFile);
        } catch (fileError) {
          throw Exception('Failed to prepare attachment for upload');
        }
      } else {
        throw Exception('Attachment file does not exist');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(
          data['message'] ?? 'Failed to submit adjustment request',
        );
      }
    } catch (e) {
      print('Error in _submitWithAttachment: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _submitWithoutAttachment({
    required String dateScan,
    required String adjustType,
    required String reason,
    required List<Map<String, int>> approvers,
    required String token,
  }) async {
    try {
      final requestBody = {
        'date_scan': dateScan,
        'adjust_type': adjustType,
        'reason': reason,
        'approvers': approvers,
      };

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}attendance/submit-adjustment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        try {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Adjustment request failed');
        } catch (_) {
          throw Exception('Server error: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error in _submitWithoutAttachment: $e');
      rethrow;
    }
  }
}
