import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/global_service.dart';

class NotificationRepository {
  final String baseUrl = ServerService().baseUrl;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Per server: whether `GET /notifications/overview` has worked (true) or
  /// answered 404 because it is not deployed yet (false).
  static final Map<String, bool> _overviewAvailable = {};

  /// GET /notifications/overview: HR notifications, announcements and all
  /// unread counts in one call. With [countsOnly] only the counts are sent.
  ///
  /// Returns the response's `data`, or null when the server does not have
  /// this endpoint, so the caller can use the older endpoints instead.
  Future<Map<String, dynamic>?> getOverview({
    bool countsOnly = false,
    int perPage = 20,
  }) async {
    if (_overviewAvailable[baseUrl] == false) return null;

    final token = await _getAuthToken();
    if (token == null) throw Exception('No authentication token found');

    final uri = Uri.parse('${baseUrl}notifications/overview').replace(
      queryParameters: {
        'per_page': '$perPage',
        if (countsOnly) 'counts_only': '1',
      },
    );
    final response = await http
        .get(uri, headers: _getHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 404 && _overviewAvailable[baseUrl] != true) {
      _overviewAvailable[baseUrl] = false;
      return null;
    }
    if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    }
    if (response.statusCode != 200) {
      throw Exception('Failed to get overview: ${response.statusCode}');
    }
    final body = json.decode(response.body);
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw Exception('API returned success: false');
    }
    _overviewAvailable[baseUrl] = true;
    final data = body['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<NotificationCountResponse> getUnreadCount() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http
          .get(
            Uri.parse('${baseUrl}notifications/unread-count'),
            headers: _getHeaders(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return NotificationCountResponse.fromJson(jsonData);
        } else {
          throw Exception('API returned success: false');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to get unread count: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<NotificationResponse> getNotifications({
    int page = 1,
    int perPage = 20,
    String? type,
    bool? isRead,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (type != null) queryParams['type'] = type;
      if (isRead != null) queryParams['is_read'] = isRead.toString();

      final uri = Uri.parse(
        '${baseUrl}notifications/with-details',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      print('📱 Notifications API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return NotificationResponse.fromJson(jsonData);
        } else {
          throw Exception('API returned success: false');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to get notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http
          .patch(
            Uri.parse('${baseUrl}notifications/$notificationId/mark-read'),
            headers: _getHeaders(token),
            body: json.encode({}),
          )
          .timeout(const Duration(seconds: 10));

      print('📖 Mark as read API response: ${response.statusCode}');
      print(
        '📖 Mark as read URL: ${baseUrl}notifications/$notificationId/mark-read',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('📖 Mark as read response data: $jsonData');
        return jsonData['success'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        print('📖 Mark as read failed with status: ${response.statusCode}');
        print('📖 Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http
          .patch(
            Uri.parse('${baseUrl}notifications/mark-all-read'),
            headers: _getHeaders(token),
            body: json.encode({}),
          )
          .timeout(const Duration(seconds: 10));
      ;

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
