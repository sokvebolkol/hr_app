import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
import '../services/global_service.dart';

class ProfileRepository {
  final ServerService _serverService = ServerService();

  // Get user profile from API
  Future<UserProfile?> getUserProfile() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final userId = pref.getString("userId");
      final token = pref.getString("token");

      if (userId == null) {
        throw Exception('User ID not found in local storage');
      }

      if (token == null) {
        throw Exception('Token not found in local storage');
      }
      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}user/profile/$userId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('User Profile Data: $data');
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      // Remove print statement to avoid redundancy
      return null;
      // throw Exception('Error fetching profile: $e');
    }
  }

  // Upload profile image
  Future<ProfileUploadResult> uploadProfileImage(File imageFile) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final userId = pref.getString("userId");
      final token = pref.getString("token");

      if (userId == null) {
        throw Exception('User ID not found');
      }

      if (token == null) {
        throw Exception('Token not found');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_serverService.baseUrl}user/upload-profile'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['uid'] = userId;
      request.files.add(
        await http.MultipartFile.fromPath('profile_image', imageFile.path),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = json.decode(respStr);

        return ProfileUploadResult(
          success: true,
          message: data['message'] ?? 'Profile image uploaded successfully',
          profileImageUrl: data['profile_image_url'],
        );
      } else {
        final respStr = await response.stream.bytesToString();
        String errorMessage = 'Failed to upload profile image';

        try {
          final errorData = json.decode(respStr);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // Use default error message if response is not JSON
        }

        return ProfileUploadResult(
          success: false,
          message: '$errorMessage (${response.statusCode})',
        );
      }
    } catch (e) {
      return ProfileUploadResult(
        success: false,
        message: 'Error uploading image: $e',
      );
    }
  }

  // Logout user (call API and clear local data)
  Future<void> logout() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final token = pref.getString("token");

      if (token != null) {
        // Call logout endpoint
        final response = await http.post(
          Uri.parse('${_serverService.baseUrl}logout'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        // Log the response for debugging (optional)
        print('Logout response: ${response.statusCode}');
      }
    } catch (e) {
      // Even if the API call fails, we should still clear local data
      print('Error during logout API call: $e');
    } finally {
      // Always clear local data regardless of API response
      SharedPreferences pref = await SharedPreferences.getInstance();
      await pref.clear();
    }
  }
}

class ProfileUploadResult {
  final bool success;
  final String message;
  final String? profileImageUrl;

  ProfileUploadResult({
    required this.success,
    required this.message,
    this.profileImageUrl,
  });
}
