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

      if (userId == null) {
        throw Exception('User ID not found in local storage');
      }

      final response = await http.get(
        Uri.parse('${_serverService.baseUrl}user/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // Upload profile image
  Future<ProfileUploadResult> uploadProfileImage(File imageFile) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final userId = pref.getString("userId");

      if (userId == null) {
        throw Exception('User ID not found');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${_serverService.baseUrl}user/upload-profile'),
      );

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

  // Logout user (clear local data)
  Future<void> logout() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.clear();
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
