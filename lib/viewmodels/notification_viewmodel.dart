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
      print('Error fetching unread count: $e');
      // Don't show error to user for background updates
    }
  }

  Future<void> fetchNotifications({
    bool refresh = false,
    int page = 1,
    String? type,
    bool? isRead,
  }) async {
    // Use provided parameters or fall back to stored filter values
    final filterType = type ?? _selectedType;
    final filterIsRead = isRead ?? _selectedReadStatus;

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
        type: filterType,
        isRead: filterIsRead,
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

    } catch (e) {
      _error = e.toString();
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

  Future<bool> markAsRead(int notificationId) async {
    try {

      final success = await _repository.markAsRead(notificationId);

      if (success) {
        // Update the local notification state immediately
        final notificationIndex = _notifications.indexWhere(
          (n) => n.id == notificationId,
        );
        if (notificationIndex != -1) {
          _notifications[notificationIndex] = NotificationModel(
            id: _notifications[notificationIndex].id,
            title: _notifications[notificationIndex].title,
            body: _notifications[notificationIndex].body,
            type: _notifications[notificationIndex].type,
            category: _notifications[notificationIndex].category,
            data: _notifications[notificationIndex].data,
            isRead: true, // Mark as read locally
            readAt: DateTime.now().toIso8601String(),
            createdAt: _notifications[notificationIndex].createdAt,
            timeAgo: _notifications[notificationIndex].timeAgo,
            isRecent: _notifications[notificationIndex].isRecent,
            staffLeaveRequest:
                _notifications[notificationIndex]
                    .staffLeaveRequest, // Updated field name
            ownLeaveRequestData:
                _notifications[notificationIndex]
                    .ownLeaveRequestData, // Updated field name
          );

          // Update unread count
          if (_unreadCount > 0) {
            _unreadCount--;
          }

          notifyListeners();
          print('✅ Notification $notificationId marked as read successfully');
        }

        return true;
      } else {
        print('Failed to mark notification $notificationId as read');
        return false;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final success = await _repository.markAllAsRead();

      if (success) {
        _notifications =
            _notifications.map((notification) {
              return NotificationModel(
                id: notification.id,
                title: notification.title,
                body: notification.body,
                type: notification.type,
                category: notification.category,
                data: notification.data,
                isRead: true,
                readAt: DateTime.now().toIso8601String(),
                createdAt: notification.createdAt,
                timeAgo: notification.timeAgo,
                isRecent: notification.isRecent,
                staffLeaveRequest:
                    notification.staffLeaveRequest, // Updated field name
                ownLeaveRequestData:
                    notification.ownLeaveRequestData, // Updated field name
              );
            }).toList();

        _unreadCount = 0;

        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setTypeFilter(String? type) {
    if (_selectedType != type) {
      _selectedType = type;
      print('🔄 Type filter set to: $type');
    }
  }

  void setReadStatusFilter(bool? isRead) {
    if (_selectedReadStatus != isRead) {
      _selectedReadStatus = isRead;
      print('🔄 Read status filter set to: $isRead');
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

  // Refresh method for pull-to-refresh
  Future<void> refresh() async {
    await fetchNotifications(refresh: true);
  }

  // Get filtered notifications locally (for better performance)
  List<NotificationModel> getFilteredNotifications({
    String? type,
    bool? isRead,
  }) {
    List<NotificationModel> filtered = List.from(_notifications);

    if (type != null) {
      if (type == 'my_alert') {
        // My Alert includes all types except leave and announcement
        filtered =
            filtered
                .where((n) => n.type != 'leave' && n.type != 'announcement')
                .toList();
      } else {
        filtered = filtered.where((n) => n.type == type).toList();
      }
    }

    if (isRead != null) {
      filtered = filtered.where((n) => n.isRead == isRead).toList();
    }

    return filtered;
  }

  // Get notification counts by type (unread only)
  Map<String, int> getNotificationCounts() {
    final unreadNotifications = _notifications.where((n) => !n.isRead);

    return {
      'my_alert':
          unreadNotifications
              .where((n) => n.type != 'leave' && n.type != 'announcement')
              .length,
      'leave': unreadNotifications.where((n) => n.type == 'leave').length,
      'announcement':
          unreadNotifications.where((n) => n.type == 'announcement').length,
      'total': unreadNotifications.length,
    };
  }

  // Get unread notifications by type and action
  List<NotificationModel> getUnreadNotificationsByType(String type) {
    final unreadNotifications = _notifications.where((n) => !n.isRead);

    switch (type.toLowerCase()) {
      case 'leave_request':
        // New leave requests for approval
        return unreadNotifications
            .where(
              (n) => n.type == 'leave' && n.data['action'] == 'new_request',
            )
            .toList();
      case 'leave_approval':
      case 'leave_status':
        // Approved/rejected/submitted leave notifications
        return unreadNotifications
            .where(
              (n) =>
                  n.type == 'leave' &&
                  (n.data['action'] == 'approved' ||
                      n.data['action'] == 'rejected' ||
                      n.data['action'] == 'submitted' ||
                      n.data['action'] == 'status_update'),
            )
            .toList();
      case 'leave':
        return unreadNotifications.where((n) => n.type == 'leave').toList();
      case 'announcement':
        return unreadNotifications
            .where((n) => n.type == 'announcement')
            .toList();
      default:
        return unreadNotifications.toList();
    }
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

    // Navigation logic will be handled in the UI layer
  }

  // Update notification in list after external changes
  void updateNotification(NotificationModel updatedNotification) {
    final index = _notifications.indexWhere(
      (n) => n.id == updatedNotification.id,
    );
    if (index != -1) {
      _notifications[index] = updatedNotification;
      // Update unread count if read status changed
      _updateUnreadCount();

      notifyListeners();
    }
  }

  // Remove notification from list
  void removeNotification(int notificationId) {
    final removedNotification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw StateError('Notification not found'),
    );

    _notifications.removeWhere((n) => n.id == notificationId);

    // Update unread count if removed notification was unread
    if (!removedNotification.isRead && _unreadCount > 0) {
      _unreadCount--;
    }

    notifyListeners();
  }

  // Add new notification (for real-time updates)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    if (!notification.isRead) {
      _unreadCount++;
    }
    notifyListeners();
  }

  // Private method to recalculate unread count from current notifications
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  // Force refresh unread count from local notifications
  void recalculateUnreadCount() {
    _updateUnreadCount();
    notifyListeners();
  }

  // Check if notification has leave information - Updated method
  bool hasLeaveInformation(NotificationModel notification) {
    return notification.type == 'leave' && notification.leaveData != null;
  }

  // Get leave information from notification - Updated method
  Map<String, dynamic>? getLeaveInformation(NotificationModel notification) {
    if (hasLeaveInformation(notification)) {
      return notification.leaveData;
    }
    return null;
  }

  // Search notifications
  List<NotificationModel> searchNotifications(String query) {
    if (query.isEmpty) return _notifications;

    final lowercaseQuery = query.toLowerCase();
    return _notifications.where((notification) {
      return notification.title.toLowerCase().contains(lowercaseQuery) ||
          notification.body.toLowerCase().contains(lowercaseQuery) ||
          notification.type.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get recent notifications (created in last 24 hours)
  List<NotificationModel> getRecentNotifications() {
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));

    return _notifications.where((notification) {
      try {
        final createdAt = DateTime.parse(notification.createdAt);
        return createdAt.isAfter(oneDayAgo);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Get leave request notifications for CEO/Approvers
  List<NotificationModel> getLeaveRequestNotifications() {
    return _notifications
        .where(
          (n) =>
              !n.isRead &&
              n.type == 'leave' &&
              n.data['action'] == 'new_request',
        )
        .toList();
  }

  // Get leave status notifications for requesters
  List<NotificationModel> getLeaveStatusNotifications() {
    return _notifications
        .where(
          (n) =>
              !n.isRead &&
              n.type == 'leave' &&
              (n.data['action'] == 'approved' ||
                  n.data['action'] == 'rejected' ||
                  n.data['action'] == 'submitted' ||
                  n.data['action'] == 'status_update'),
        )
        .toList();
  }

  // Get notification counts for dashboard badges
  Map<String, int> getDashboardNotificationCounts() {
    final leaveRequests = getLeaveRequestNotifications().length;
    final leaveStatus = getLeaveStatusNotifications().length;

    return {
      'leave_request': leaveRequests,
      'leave_status': leaveStatus,
      'total': leaveRequests + leaveStatus,
    };
  }

  @override
  void dispose() {
    stopPeriodicUnreadCountUpdate();
    super.dispose();
  }
}
