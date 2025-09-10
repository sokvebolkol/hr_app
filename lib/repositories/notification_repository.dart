import 'dart:convert';
import 'package:chokchey_hr_app/services/global_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';

class NotificationRepository {
  static const String _notificationsKey = 'local_notifications';
  static const String _lastSyncKey = 'last_notification_sync';

  /// Save notification locally
  Future<void> saveNotificationLocally(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getLocalNotifications();

      // Add new notification at the beginning
      notifications.insert(0, notification);

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }

      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
    } catch (e) {
      print('❌ Error saving notification locally: $e');
    }
  }

  /// Get local notifications
  Future<List<NotificationModel>> getLocalNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationsKey);

      if (jsonString == null) return [];

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error getting local notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notifications = await getLocalNotifications();
      final updatedNotifications =
          notifications.map((notification) {
            if (notification.id == notificationId) {
              return notification.copyWith(isRead: true);
            }
            return notification;
          }).toList();

      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));

      // Also mark as read on server
      await _markAsReadOnServer(notificationId);
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final notifications = await getLocalNotifications();
      final updatedNotifications =
          notifications
              .map((notification) => notification.copyWith(isRead: true))
              .toList();

      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));

      // Also mark all as read on server
      await _markAllAsReadOnServer();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final notifications = await getLocalNotifications();
      return notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Clear all local notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// Update FCM token on server
  Future<void> updateFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      if (authToken == null) return;

      final response = await http.post(
        Uri.parse('${ServerService().baseUrl}/update-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token, 'platform': 'mobile'}),
      );

      if (response.statusCode == 200) {
        print('✅ FCM token updated on server');
      } else {
        print('❌ Failed to update FCM token on server: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  /// Sync notifications from server
  Future<List<NotificationModel>> syncNotificationsFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      if (authToken == null) return [];

      final lastSync = prefs.getString(_lastSyncKey);
      final url =
          lastSync != null
              ? '${ServerService().baseUrl}/notifications?since=$lastSync'
              : '${ServerService().baseUrl}/notifications';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications =
            (data['notifications'] as List<dynamic>)
                .map((json) => NotificationModel.fromJson(json))
                .toList();

        // Merge with local notifications
        await _mergeWithLocalNotifications(notifications);

        // Update last sync time
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

        return notifications;
      } else {
        print('❌ Failed to sync notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error syncing notifications: $e');
      return [];
    }
  }

  /// Merge server notifications with local ones
  Future<void> _mergeWithLocalNotifications(
    List<NotificationModel> serverNotifications,
  ) async {
    try {
      final localNotifications = await getLocalNotifications();
      final mergedNotifications = <NotificationModel>[];

      // Add server notifications
      mergedNotifications.addAll(serverNotifications);

      // Add local notifications that are not on server
      for (final localNotification in localNotifications) {
        if (!serverNotifications.any((n) => n.id == localNotification.id)) {
          mergedNotifications.add(localNotification);
        }
      }

      // Sort by creation date (newest first)
      mergedNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Keep only last 100 notifications
      if (mergedNotifications.length > 100) {
        mergedNotifications.removeRange(100, mergedNotifications.length);
      }

      // Save merged notifications
      final prefs = await SharedPreferences.getInstance();
      final jsonList = mergedNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
    } catch (e) {
      print('❌ Error merging notifications: $e');
    }
  }

  /// Mark notification as read on server
  Future<void> _markAsReadOnServer(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      if (authToken == null) return;

      await http.patch(
        Uri.parse(
          '${ServerService().baseUrl}/notifications/$notificationId/read',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
    } catch (e) {
      print('❌ Error marking notification as read on server: $e');
    }
  }

  /// Mark all notifications as read on server
  Future<void> _markAllAsReadOnServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      if (authToken == null) return;

      await http.patch(
        Uri.parse('${ServerService().baseUrl}/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
    } catch (e) {
      print('❌ Error marking all notifications as read on server: $e');
    }
  }
}
