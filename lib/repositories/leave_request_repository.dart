import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constant.dart';
import '../models/leave_type_model.dart';
import '../models/approver_model.dart';
import '../services/global_service.dart';
import '../services/http_service.dart';

class LeaveRequestRepository {
  final ServerService _serverService = ServerService();

  Future<LeaveRequestData> getLeaveRequestData() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      // Use the shared HttpService (same path as the dashboard): it checks the
      // connection/server first, applies a sane timeout, and throws typed,
      // readable errors instead of hanging silently.
      final response = await HttpService.get(
        url: '${_serverService.baseUrl}leave-request-screen',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Some endpoints wrap the payload in a `data` object; fall back to the
        // root if it isn't present so both shapes parse correctly.
        final data =
            (decoded is Map && decoded['data'] is Map)
                ? decoded['data']
                : decoded;

        return LeaveRequestData(
          leaveTypes:
              ((data['leaveTypes'] ?? []) as List)
                  .map((e) => LeaveTypeModel.fromJson(e))
                  .toList(),
          approvers:
              ((data['approvers'] ?? []) as List)
                  .map((e) => ApproverModel.fromJson(e))
                  .toList(),
          holidays: List<String>.from(data['holidays'] ?? []),
          userId: data['userId']?.toString() ?? '',
        );
      } else {
        throw Exception(
          'Failed to fetch leave request data (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      // Surface the real cause so failures are diagnosable instead of hidden
      // behind a generic message.
      throw Exception('Error fetching leave request data: $e');
    }
  }

  // Updated submit leave request function with validation
  Future<LeaveRequestResponse> submitLeaveRequest({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required int leaveFor,
    required String halfDaySession,
    required double totalLeave,
    required List<Map<String, dynamic>> approvers,
    File? file,
  }) async {
    try {
      // Validate total leave
      if (totalLeave <= 0) {
        throw Exception('Total leave days must be greater than 0');
      }

      // Validate other required fields
      if (leaveType.isEmpty) {
        throw Exception('Please select a leave type');
      }

      if (fromDate.isEmpty || toDate.isEmpty) {
        throw Exception('Please select valid dates');
      }

      if (reason.trim().isEmpty) {
        throw Exception('Please provide a reason for your leave');
      }

      if (approvers.isEmpty) {
        throw Exception('Please select at least one approver');
      }

      // Validate date range
      final startDate = DateTime.parse(fromDate);
      final endDate = DateTime.parse(toDate);

      if (endDate.isBefore(startDate)) {
        throw Exception('End date cannot be before start date');
      }

      // Validate future dates (optional - remove if past dates are allowed)
      // final today = DateTime.now();
      // if (startDate.isBefore(DateTime(today.year, today.month, today.day))) {
      //   throw Exception('Leave start date cannot be in the past');
      // }

      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      // Check if this leave type requires a file
      final requiresFile = _leaveTypeRequiresFile(leaveType);
      if (requiresFile && file == null) {
        throw Exception(
          '${_getLeaveTypeName(leaveType)} requires medical certificate or supporting document',
        );
      }

      // Additional file validation if file is provided
      if (file != null) {
        if (!await file.exists()) {
          throw Exception('Selected file does not exist');
        }

        if (!isValidImageFile(file)) {
          throw Exception('Please select a valid file type (JPG, JPEG, PNG)');
        }

        if (!await isValidFileSize(file)) {
          throw Exception('File size must be less than 5MB');
        }
      }

      // Use multipart request if there is a file
      if (file != null) {
        return await _submitWithFile(
          leaveType: leaveType,
          fromDate: fromDate,
          toDate: toDate,
          reason: reason,
          leaveFor: leaveFor,
          halfDaySession: halfDaySession,
          totalLeave: totalLeave,
          approvers: approvers,
          file: file,
          token: token,
        );
      } else {
        return await _submitWithoutFile(
          leaveType: leaveType,
          fromDate: fromDate,
          toDate: toDate,
          reason: reason,
          leaveFor: leaveFor,
          halfDaySession: halfDaySession,
          totalLeave: totalLeave,
          approvers: approvers,
          token: token,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Submit leave request with single file (multipart)
  Future<LeaveRequestResponse> _submitWithFile({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required int leaveFor,
    required String halfDaySession,
    required double totalLeave,
    required List<Map<String, dynamic>> approvers,
    required File file,
    required String token,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_serverService.baseUrl}request-leave'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields.addAll({
        'leave_type': leaveType,
        'from_date': fromDate,
        'to_date': toDate,
        'reason': reason,
        'leave_for': leaveFor.toString(),
        'leave_session': halfDaySession,
        'total_leave': totalLeave.toString(),
      });

      // Add approvers as individual fields (not JSON encoded)
      for (int i = 0; i < approvers.length; i++) {
        final approver = approvers[i];
        request.fields['approvers[$i][eid]'] = approver['eid'].toString();
        request.fields['approvers[$i][prio]'] = approver['prio'].toString();

        // Add other approver fields if they exist
        if (approver['dname'] != null) {
          request.fields['approvers[$i][dname]'] = approver['dname'].toString();
        }
        if (approver['token'] != null) {
          request.fields['approvers[$i][token]'] = approver['token'].toString();
        }
      }
      if (await file.exists()) {
        try {
          final multipartFile = await http.MultipartFile.fromPath(
            'file',
            file.path,
          );

          request.files.add(multipartFile);
        } catch (fileError) {
          throw Exception('Failed to prepare file for upload');
        }
      } else {
        throw Exception('File does not exist at path: ${file.path}');
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return LeaveRequestResponse.fromJson(data);
      } else {
        // For non-success status codes, still parse the response
        // but the response object will have success: false
        final errorResponse = LeaveRequestResponse.fromJson(data);

        // If the backend returned a structured error, throw with the message
        if (!errorResponse.success) {
          throw Exception(errorResponse.message);
        }

        // Fallback error handling
        throw Exception(
          data['message'] ?? 'Failed to submit leave request with file',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Submit leave request without file (regular JSON)
  Future<LeaveRequestResponse> _submitWithoutFile({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required int leaveFor,
    required String halfDaySession,
    required double totalLeave,
    required List<Map<String, dynamic>> approvers,
    required String token,
  }) async {
    final body = {
      "leave_type": leaveType,
      "from_date": fromDate,
      "to_date": toDate,
      "reason": reason,
      "leave_for": leaveFor,
      "leave_session": halfDaySession,
      "total_leave": totalLeave,
      "approvers": approvers,
    };

    final response = await http.post(
      Uri.parse('${_serverService.baseUrl}request-leave'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    // Parse response regardless of status code
    final data = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return LeaveRequestResponse.fromJson(data);
    } else {
      // For non-success status codes, still parse the response
      final errorResponse = LeaveRequestResponse.fromJson(data);

      // If the backend returned a structured error, throw with the message
      if (!errorResponse.success) {
        throw Exception(errorResponse.message);
      }

      // Fallback error handling
      throw Exception(data['message'] ?? 'Failed to submit leave request');
    }
  }

  // Make this method public by removing the underscore
  bool leaveTypeRequiresFile(String leaveType) {
    final requiresFile = [sickLeave, maternityLeave, specialLeave];

    return requiresFile.any(
      (type) => leaveType.toLowerCase().contains(type.toLowerCase()),
    );
  }

  // Update the private method to use the public one
  bool _leaveTypeRequiresFile(String leaveType) {
    return leaveTypeRequiresFile(leaveType);
  }

  // Helper function to get readable leave type name
  String _getLeaveTypeName(String leaveType) {
    if (leaveType.toLowerCase().contains('sick')) return 'Sick Leave';
    if (leaveType.toLowerCase().contains('maternity')) return 'Maternity Leave';
    if (leaveType.toLowerCase().contains('special')) return 'Special Leave';
    return leaveType;
  }

  // Helper function to get file extension
  String _getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  // Validate image file - updated to be more permissive
  bool isValidImageFile(File file) {
    final validExtensions = ['jpg', 'jpeg', 'png'];
    final extension = _getFileExtension(file.path);
    return validExtensions.contains(extension);
  }

  // Check if file size is acceptable (max 5MB)
  Future<bool> isValidFileSize(File file, {int maxSizeInMB = 5}) async {
    if (!await file.exists()) return false;

    final fileSizeInBytes = await file.length();
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024; // Convert MB to bytes

    return fileSizeInBytes <= maxSizeInBytes;
  }

  // Helper method to validate leave request data
  String? validateLeaveRequest({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required double totalLeave,
    required List<Map<String, dynamic>> approvers,
    File? file,
  }) {
    // Validate total leave
    if (totalLeave <= 0) {
      return 'Total leave days must be greater than 0';
    }

    // Validate leave type
    if (leaveType.isEmpty) {
      return 'Please select a leave type';
    }

    // Validate dates
    if (fromDate.isEmpty || toDate.isEmpty) {
      return 'Please select valid dates';
    }

    try {
      final startDate = DateTime.parse(fromDate);
      final endDate = DateTime.parse(toDate);

      if (endDate.isBefore(startDate)) {
        return 'End date cannot be before start date';
      }

      // Check if dates are in the past (optional)
      final today = DateTime.now();
      if (startDate.isBefore(DateTime(today.year, today.month, today.day))) {
        return ' cannot be in the past';
      }
    } catch (e) {
      return 'Invalid date format';
    }

    // Validate reason
    if (reason.trim().isEmpty) {
      return 'Please provide a reason for your leave';
    }

    if (reason.trim().length < 10) {
      return 'Reason must be at least 10 characters long';
    }

    // Validate approvers
    if (approvers.isEmpty) {
      return 'Please select at least one approver';
    }

    // Validate file if required
    final requiresFile = _leaveTypeRequiresFile(leaveType);
    if (requiresFile && file == null) {
      return '${_getLeaveTypeName(leaveType)} requires medical certificate or supporting document';
    }

    return null; // No validation errors
  }

  // Enhanced validation for total leave calculation
  static double calculateTotalLeave({
    required DateTime fromDate,
    required DateTime toDate,
    required int leaveFor, // 1 = Full Day, 2 = Half Day
    List<String> holidays = const [],
  }) {
    if (toDate.isBefore(fromDate)) {
      throw Exception('End date cannot be before start date');
    }

    double totalDays = 0;
    DateTime currentDate = fromDate;

    while (currentDate.isBefore(toDate) ||
        currentDate.isAtSameMomentAs(toDate)) {
      // Skip weekends (Saturday = 6, Sunday = 7)
      if (currentDate.weekday != DateTime.saturday &&
          currentDate.weekday != DateTime.sunday) {
        // Check if it's not a holiday
        final dateString = currentDate.toIso8601String().split('T')[0];
        if (!holidays.contains(dateString)) {
          if (leaveFor == 2) {
            // Half day
            totalDays += 0.5;
          } else {
            // Full day
            totalDays += 1.0;
          }
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (totalDays <= 0) {
      throw Exception('No valid working days found in the selected date range');
    }

    return totalDays;
  }
}

class LeaveRequestData {
  final List<LeaveTypeModel> leaveTypes;
  final List<ApproverModel> approvers;
  final List<String> holidays;
  final String userId;

  LeaveRequestData({
    required this.leaveTypes,
    required this.approvers,
    required this.holidays,
    required this.userId,
  });
}

// Updated response model for submit leave request
class LeaveRequestResponse {
  final bool success;
  final String message;
  final String? lreid;
  final String? fileUrl;

  LeaveRequestResponse({
    required this.success,
    required this.message,
    this.lreid,
    this.fileUrl,
  });

  factory LeaveRequestResponse.fromJson(Map<String, dynamic> json) {
    return LeaveRequestResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      lreid: json['data']?['lreid'],
      fileUrl: json['data']?['file_url'],
    );
  }
}
