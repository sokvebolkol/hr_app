import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  // State variables
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  NotificationPagination? _pagination;
  NotificationSummary? _summary;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  NotificationPagination? get pagination => _pagination;
  NotificationSummary? get summary => _summary;
  bool get hasMorePages => _pagination?.hasMorePages ?? false;

  // Filter states
  String? _selectedType;
  bool? _selectedReadStatus;

  String? get selectedType => _selectedType;
  bool? get selectedReadStatus => _selectedReadStatus;

  // Timer for periodic updates
  Timer? _timer;

  void startPeriodicUnreadCountUpdate() {
    fetchUnreadCount(); // Initial fetch

    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      fetchUnreadCount();
    });
  }

  void stopPeriodicUnreadCountUpdate() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _repository.getUnreadCount();
      _unreadCount = response.unreadCount;
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      // Don't show error to user for background updates
    }
  }

  Future<void> fetchNotifications({bool refresh = false, int page = 1}) async {
    if (refresh) {
      _isLoading = true;
      _error = null;
      _notifications.clear();
    } else if (page > 1) {
      _isLoadingMore = true;
    } else {
      _isLoading = true;
      _error = null;
    }

    notifyListeners();

    try {
      final response = await _repository.getNotifications(
        page: page,
        type: _selectedType,
        isRead: _selectedReadStatus,
      );

      if (refresh || page == 1) {
        _notifications = response.notifications;
      } else {
        _notifications.addAll(response.notifications);
      }

      _pagination = response.pagination;
      _summary = response.summary;
      _unreadCount = response.summary.unread;
      _error = null;

      print('✅ Loaded ${response.notifications.length} notifications');
    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || !hasMorePages) return;

    final nextPage = (_pagination?.currentPage ?? 0) + 1;
    await fetchNotifications(page: nextPage);
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _repository.markAsRead(notificationId);

      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(
            isRead: true,
            readAt: DateTime.now().toIso8601String(),
          );

          // Update unread count
          if (_unreadCount > 0) _unreadCount--;

          notifyListeners();

          print('✅ Notification $notificationId marked as read');
        }
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _repository.markAllAsRead();

      if (success) {
        // Update local state
        _notifications =
            _notifications.map((notification) {
              return notification.copyWith(
                isRead: true,
                readAt: DateTime.now().toIso8601String(),
              );
            }).toList();

        _unreadCount = 0;
        notifyListeners();

        print('✅ All notifications marked as read');
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  void setTypeFilter(String? type) {
    if (_selectedType != type) {
      _selectedType = type;
      fetchNotifications(refresh: true);
    }
  }

  void setReadStatusFilter(bool? isRead) {
    if (_selectedReadStatus != isRead) {
      _selectedReadStatus = isRead;
      fetchNotifications(refresh: true);
    }
  }

  void clearFilters() {
    _selectedType = null;
    _selectedReadStatus = null;
    fetchNotifications(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Handle notification click actions
  void handleNotificationClick(NotificationModel notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Handle click action based on notification data
    final clickAction = notification.data['click_action'];
    print('🔔 Notification clicked: $clickAction');

    // You can add navigation logic here based on click_action
    // For example:
    // if (clickAction == 'leave_screen') {
    //   NavigationService.navigateToLeaveScreen(notification.data['leave_id']);
    // }
  }

  @override
  void dispose() {
    stopPeriodicUnreadCountUpdate();
    super.dispose();
  }
}
