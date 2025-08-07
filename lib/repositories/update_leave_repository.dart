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
        final request = http.MultipartRequest('PUT', url);

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
        // Regular JSON request without file
        final response = await http.put(
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
}
