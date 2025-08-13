import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/global_service.dart';

class LeaveDetailRepository {
  final ServerService _serverService = ServerService();

  // Cancel leave request
  Future<bool> cancelLeaveRequest(String leaveId) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}leave/$leaveId/cancel'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'leave_id': leaveId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to cancel leave: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error cancelling leave: $e');
    }
  }

  // Enhanced Update leave request with proper endpoint and additional features
  Future<Map<String, dynamic>> updateLeaveRequest({
    required String leaveId,
    required String fromDate,
    required String toDate,
    required String reason,
    required String leaveTypeId,
    required String numDays,
    required String leavePeriod, // "1" for full day, "0.5" for half day
    String? halfDaySession, // "morning" or "afternoon" for half day
    File? documentFile, // Optional document file
    bool removeExistingDocument = false,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      // Prepare multipart request if there's a file
      late http.Response response;

      if (documentFile != null) {
        // Create multipart request for file upload
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('${_serverService.baseUrl}leave/$leaveId'),
        );

        // Add headers
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

        // Add fields
        request.fields.addAll({
          'from_date': fromDate,
          'to_date': toDate,
          'reason': reason,
          'leave_type_id': leaveTypeId,
          'num_days': numDays,
          'leave_period': leavePeriod,
          if (halfDaySession != null) 'half_day_session': halfDaySession,
          if (removeExistingDocument) 'remove_existing_document': 'true',
        });

        // Add file
        var fileStream = http.MultipartFile.fromBytes(
          'document',
          await documentFile.readAsBytes(),
          filename: documentFile.path.split('/').last,
        );
        request.files.add(fileStream);

        // Send request
        var streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Regular JSON request without file
        response = await http.put(
          Uri.parse('${_serverService.baseUrl}leave/$leaveId'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({
            'from_date': fromDate,
            'to_date': toDate,
            'reason': reason,
            'leave_type_id': leaveTypeId,
            'num_days': numDays,
            'leave_period': leavePeriod,
            if (halfDaySession != null) 'half_day_session': halfDaySession,
            if (removeExistingDocument) 'remove_existing_document': true,
          }),
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] == true,
          'message': data['message'] ?? 'Leave request updated successfully',
          'data': data['data'],
          'errors': null,
        };
      } else if (response.statusCode == 422) {
        // Validation errors
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Validation failed',
          'data': null,
          'errors': data['errors'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update leave: ${response.statusCode}',
          'data': null,
          'errors': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating leave: $e',
        'data': null,
        'errors': null,
      };
    }
  }

  // Get leave details for editing
  Future<Map<String, dynamic>> getLeaveDetails(String leaveId) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}leave/$leaveId/edit'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': 'Leave details retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'data': null,
          'message': 'Failed to get leave details: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error getting leave details: $e',
      };
    }
  }

  // Validate leave dates before updating
  Future<Map<String, dynamic>> validateLeaveDates({
    required String fromDate,
    required String toDate,
    required String leaveTypeId,
    required String employeeId,
    String? excludeLeaveId, // Exclude current leave ID from validation
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}leave/validate-dates'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'from_date': fromDate,
          'to_date': toDate,
          'leave_type_id': leaveTypeId,
          'employee_id': employeeId,
          if (excludeLeaveId != null) 'exclude_leave_id': excludeLeaveId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'valid': data['valid'] == true,
          'message': data['message'],
          'conflicts': data['conflicts'],
          'available_days': data['available_days'],
        };
      } else {
        return {
          'success': false,
          'valid': false,
          'message': 'Validation failed: ${response.statusCode}',
          'conflicts': null,
          'available_days': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'valid': false,
        'message': 'Error validating dates: $e',
        'conflicts': null,
        'available_days': null,
      };
    }
  }

  // Send follow-up message
  Future<bool> sendFollowUpMessage(String leaveId, String message) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.post(
        Uri.parse('${_serverService.baseUrl}follow-up-leave'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'leave_id': leaveId, 'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        throw Exception('Failed to send follow-up: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending follow-up: $e');
    }
  }

  // Get available leave balance for employee
  Future<Map<String, dynamic>> getLeaveBalance(String employeeId) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse(
          '${_serverService.baseUrl}employee/$employeeId/leave-balance',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'message': 'Leave balance retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'data': null,
          'message': 'Failed to get leave balance: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'data': null,
        'message': 'Error getting leave balance: $e',
      };
    }
  }
}
