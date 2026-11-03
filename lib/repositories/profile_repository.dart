import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile_model.dart';
import '../services/global_service.dart';
import '../services/announcement_feed_cache.dart';
import '../services/announcement_unread_service.dart';
import '../services/http_service.dart';

class ProfileRepository {
  final ServerService _serverService = ServerService();

  // Profile cache shared by every ProfileRepository instance, so Home,
  // detail screens and re-mounted dashboards reuse one response. It is keyed
  // by server + user + token, so logging in as someone else, a new token or
  // an environment switch never reads a stale entry.
  static UserProfile? _cachedProfile;
  static String? _cacheKey;
  static Future<UserProfile?>? _inFlight;
  static String? _inFlightKey;

  /// Drops the cached profile. Called on logout.
  static void clearCache() {
    _cachedProfile = null;
    _cacheKey = null;
    _inFlight = null;
    _inFlightKey = null;
  }

  /// Returns the user profile.
  ///
  /// Served from cache unless [forceRefresh] is true (pull-to-refresh or
  /// after a profile edit). Concurrent calls share one request. Returns null
  /// on failure and keeps any previously cached profile.
  Future<UserProfile?> getUserProfile({bool forceRefresh = false}) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      final userId = pref.getString("userId");
      final token = pref.getString("token");

      if (userId == null || token == null) return null;

      final key = '${_serverService.baseUrl}|$userId|$token';

      if (!forceRefresh && _cacheKey == key && _cachedProfile != null) {
        return _cachedProfile;
      }

      final running = _inFlight;
      if (running != null && _inFlightKey == key) return await running;

      final request = _fetchProfile(userId, token);
      _inFlight = request;
      _inFlightKey = key;
      try {
        final profile = await request;
        if (profile != null) {
          _cachedProfile = profile;
          _cacheKey = key;
        }
        return profile ?? (_cacheKey == key ? _cachedProfile : null);
      } finally {
        if (identical(_inFlight, request)) {
          _inFlight = null;
          _inFlightKey = null;
        }
      }
    } catch (e) {
      return null;
    }
  }

  Future<UserProfile?> _fetchProfile(String userId, String token) async {
    try {
      final response = await HttpService.getAllowingErrors(
        url: '${_serverService.baseUrl}user/profile/$userId',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
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

        // The cached profile now has a stale image; next read refetches.
        clearCache();

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
        ).timeout(const Duration(seconds: 15));

        // Log the response for debugging (optional)
        print('Logout response: ${response.statusCode}');
      }
    } catch (e) {
      // Even if the API call fails, we should still clear local data
      print('Error during logout API call: $e');
    } finally {
      // Always clear local data regardless of API response, but keep device
      // level settings (landing screen choice and selected environment) so
      // they survive logout/login.
      SharedPreferences pref = await SharedPreferences.getInstance();
      final landingScreenIndex = pref.getInt('landingScreenIndex');
      final selectedEnvironment = pref.getString('selected_environment');
      await pref.clear();
      if (landingScreenIndex != null) {
        await pref.setInt('landingScreenIndex', landingScreenIndex);
      }
      if (selectedEnvironment != null) {
        await pref.setString('selected_environment', selectedEnvironment);
      }

      // Drop the Teams read markers so the next user on this device does
      // not inherit the previous user's badge state.
      await AnnouncementUnreadService.instance.reset();
      AnnouncementFeedCache.instance.clear();
      clearCache();
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
