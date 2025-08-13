import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/global_service.dart';

class UpdateLeaveRepository {
  final ServerService _serverService = ServerService();

  Future<bool> updateLeaveRequest(
    String leaveRequestId,
    Map<String, dynamic> updateData,
    XFile? documentPhoto,
  ) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        throw Exception('Token not found in local storage');
      }

      final url = Uri.parse(
        '${_serverService.baseUrl}update-leave/$leaveRequestId',
      );

      // Create multipart request for file upload if document exists
      if (documentPhoto != null) {
        final request = http.MultipartRequest('POST', url);

        // Add form fields
        updateData.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        // Add file
        final file = await http.MultipartFile.fromPath(
          'document_photo',
          documentPhoto.path,
        );
        request.files.add(file);

        // Add headers (authentication)
        request.headers['Authorization'] = 'Bearer $token';

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return jsonData['success'] ?? false;
        } else {
          throw Exception('Failed to update leave: ${response.statusCode}');
        }
      } else {
        // Changed from PUT to POST for consistency
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(updateData),
        );

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          return jsonData['success'] ?? false;
        } else {
          throw Exception('Failed to update leave: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Additional method for better error handling and response details
  Future<Map<String, dynamic>> updateLeaveRequestDetailed(
    String leaveRequestId,
    Map<String, dynamic> updateData,
    XFile? documentPhoto,
  ) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final url = Uri.parse(
        '${_serverService.baseUrl}update-leave/$leaveRequestId',
      );

      http.Response response;

      // Create multipart request for file upload if document exists
      if (documentPhoto != null) {
        final request = http.MultipartRequest('POST', url);

        // Add form fields
        updateData.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        // Add file
        final file = await http.MultipartFile.fromPath(
          'document_photo',
          documentPhoto.path,
        );
        request.files.add(file);

        // Add headers (authentication)
        request.headers['Authorization'] = 'Bearer $token';

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Regular JSON request using POST
        response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(updateData),
        );
      }

      // Parse response
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': jsonData['success'] ?? false,
          'message': jsonData['message'] ?? 'Leave updated successfully',
          'data': jsonData['data'],
        };
      } else if (response.statusCode == 422) {
        // Validation errors
        final jsonData = json.decode(response.body);
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Validation failed',
          'errors': jsonData['errors'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized access. Please login again.',
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Leave request not found.'};
      } else {
        return {
          'success': false,
          'message':
              'Failed to update leave. Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Method to cancel leave request
  Future<Map<String, dynamic>> cancelLeaveRequest(String leaveRequestId) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final url = Uri.parse(
        '${_serverService.baseUrl}cancel-leave/$leaveRequestId',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': jsonData['success'] ?? false,
          'message': jsonData['message'] ?? 'Leave cancelled successfully',
        };
      } else {
        final jsonData = json.decode(response.body);
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Failed to cancel leave request',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Method to get leave update history
  Future<Map<String, dynamic>> getLeaveUpdateHistory(
    String leaveRequestId,
  ) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token == null) {
        return {'success': false, 'message': 'Authentication token not found'};
      }

      final url = Uri.parse(
        '${_serverService.baseUrl}leave-update-history/$leaveRequestId',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'success': true,
          'data': jsonData['data'],
          'message': 'Update history retrieved successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to retrieve update history',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
