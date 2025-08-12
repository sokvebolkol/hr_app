import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constant.dart';
import '../models/leave_type_model.dart';
import '../models/approver_model.dart';
import '../services/global_service.dart';

class LeaveRequestRepository {
  final ServerService _serverService = ServerService();

  Future<LeaveRequestData> getLeaveRequestData() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}leave-request-screen'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return LeaveRequestData(
          leaveTypes:
              (data['leaveTypes'] as List)
                  .map((e) => LeaveTypeModel.fromJson(e))
                  .toList(),
          approvers:
              (data['approvers'] as List)
                  .map((e) => ApproverModel.fromJson(e))
                  .toList(),
          holidays: List<String>.from(data['holidays']),
          userId: data['userId'],
        );
      } else {
        throw Exception(
          'Failed to fetch leave request data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching leave request data: $e');
    }
  }

  // Updated submit leave request function with single file upload support
  Future<LeaveRequestResponse> submitLeaveRequest({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required int leaveFor,
    required double totalLeave,
    required List<Map<String, dynamic>> approvers,
    File? file,
  }) async {
    try {
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

      // Use multipart request if there is a file
      if (file != null) {
        return await _submitWithFile(
          leaveType: leaveType,
          fromDate: fromDate,
          toDate: toDate,
          reason: reason,
          leaveFor: leaveFor,
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
          totalLeave: totalLeave,
          approvers: approvers,
          token: token,
        );
      }
    } catch (e) {
      throw Exception('Error submitting leave request: $e');
    }
  }

  // Submit leave request with single file (multipart)
  Future<LeaveRequestResponse> _submitWithFile({
    required String leaveType,
    required String fromDate,
    required String toDate,
    required String reason,
    required int leaveFor,
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
          // Check file type before upload
          final extension = _getFileExtension(file.path);
          print('File extension: $extension');

          final multipartFile = await http.MultipartFile.fromPath(
            'file',
            file.path,
          );

          request.files.add(multipartFile);
        } catch (fileError) {
          throw Exception('Failed to prepare file for upload: $fileError');
        }
      } else {
        throw Exception('File does not exist at path: ${file.path}');
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return LeaveRequestResponse.fromJson(data);
      } else {
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          // Handle validation errors
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            String errorMessage = 'Validation failed:\n';

            errors.forEach((field, messages) {
              if (messages is List) {
                errorMessage += '• $field: ${messages.join(', ')}\n';
              }
            });

            throw Exception(errorMessage.trim());
          }

          throw Exception(
            errorData['message'] ?? 'Failed to submit leave request with file',
          );
        } catch (jsonError) {
          throw Exception(
            'Server error (${response.statusCode}): ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error in _submitWithFile: $e');
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
      "total_leave": totalLeave,
      "approvers": approvers, // Keep as array for JSON requests
    };

    print('Request body: ${json.encode(body)}');

    final response = await http.post(
      Uri.parse('${_serverService.baseUrl}request-leave'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return LeaveRequestResponse.fromJson(data);
    } else {
      try {
        final errorData = json.decode(response.body);

        // Handle validation errors
        if (errorData['errors'] != null) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          String errorMessage = 'Validation failed:\n';

          errors.forEach((field, messages) {
            if (messages is List) {
              errorMessage += '• $field: ${messages.join(', ')}\n';
            }
          });

          throw Exception(errorMessage.trim());
        }

        throw Exception(
          errorData['message'] ?? 'Failed to submit leave request',
        );
      } catch (jsonError) {
        throw Exception(
          'Server error (${response.statusCode}): ${response.body}',
        );
      }
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
    final validExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'];
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
  final String? fileUrl; // Single file URL instead of list

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
