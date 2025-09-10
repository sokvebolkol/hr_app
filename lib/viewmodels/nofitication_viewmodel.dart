import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';
import '../services/firebase_notification_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();
  final FirebaseNotificationService _notificationService = FirebaseNotificationService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  int _unreadCount = 0;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  bool get hasNotifications => _notifications.isNotEmpty;

  // Filtered notifications
  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications => 
      _notifications.where((n) => n.isRead).toList();

  List<NotificationModel> getNotificationsByType(NotificationType type) =>
      _notifications.where((n) => n.type == type).toList();

  /// Initialize notifications
  Future<void> initialize() async {
    await loadNotifications();
    await _updateUnreadCount();
    
    // Set up notification callbacks
    _notificationService.onNotificationReceived = _onNotificationReceived;
    _notificationService.onNotificationTapped = _onNotificationTapped;
  }

  /// Load notifications from local storage
  Future<void> loadNotifications() async {
    _setLoading(true);
    _setError(null);

    try {
      _notifications = await _repository.getLocalNotifications();
      await _updateUnreadCount();
    } catch (e) {
      _setError('Failed to load notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh notifications from server
  Future<void> refreshNotifications() async {
    _setRefreshing(true);
    _setError(null);

    try {
      await _repository.syncNotificationsFromServer();
      _notifications = await _repository.getLocalNotifications();
      await _updateUnreadCount();
    } catch (e) {
      _setError('Failed to refresh notifications: $e');
    } finally {
      _setRefreshing(false);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markNotificationAsRead(notificationId);
      
      // Update local list
      _notifications = _notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      await _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      
      // Update local list
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
      
      await _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      
      // Save updated list locally
      for (final notification in _notifications) {
        await _repository.saveNotificationLocally(notification);
      }
      
      await _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _repository.clearAllNotifications();
      await _notificationService.clearAllNotifications();
      
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear notifications: $e');
    }
  }

  /// Handle new notification received
  void _onNotificationReceived(NotificationModel notification) {
    _notifications.insert(0, notification);
    _updateUnreadCount();
    notifyListeners();
  }

  /// Handle notification tapped
  void _onNotificationTapped(NotificationModel notification) {
    // This will be handled by the navigation logic in the UI
    print('Notification tapped: ${notification.title}');
  }

  /// Update unread count
  Future<void> _updateUnreadCount() async {
    _unreadCount = await _repository.getUnreadNotificationCount();
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set refreshing state
  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  /// Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Get FCM token
  String? get fcmToken => _notificationService.fcmToken;

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _notificationService.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _notificationService.unsubscribeFromTopic(topic);
  }
}