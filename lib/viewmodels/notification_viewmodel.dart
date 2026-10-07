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
                _notifications[notificationIndex].staffLeaveRequest,
            ownLeaveRequestData:
                _notifications[notificationIndex].ownLeaveRequestData,
            staffAttendanceAdjustmentData:
                _notifications[notificationIndex].staffAttendanceAdjustmentData,
            ownAttendanceAdjustmentData:
                _notifications[notificationIndex].ownAttendanceAdjustmentData,
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
                staffLeaveRequest: notification.staffLeaveRequest,
                ownLeaveRequestData: notification.ownLeaveRequestData,
              );
            }).toList();

        _unreadCount = 0;
        if (_summary != null) {
          _summary = NotificationSummary(
            total: _summary!.total,
            unread: 0,
            read: _summary!.total,
            byType: _summary!.byType,
            recentUnread: 0,
          );
        }

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

  @override
  void dispose() {
    stopPeriodicUnreadCountUpdate();
    super.dispose();
  }
}
