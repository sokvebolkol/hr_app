import 'package:flutter/material.dart';
import 'dart:async';
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

  // Timer for periodic updates
  Timer? _timer;

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

  // Navigation callback
  Function(String action, Map<String, dynamic> data)? onNavigationRequired;

  /// Start periodic unread count updates
  void startPeriodicUnreadCountUpdate() {
    fetchUnreadCount(); // Initial fetch
    
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      fetchUnreadCount();
    });
  }

  /// Stop periodic unread count updates
  void stopPeriodicUnreadCountUpdate() {
    _timer?.cancel();
    _timer = null;
  }

  /// Fetch unread count only
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

  /// Fetch notifications with pagination support
  Future<void> fetchNotifications({
    bool refresh = false,
    int page = 1,
  }) async {
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

  /// Load more notifications for pagination
  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || !hasMorePages) return;

    final nextPage = (_pagination?.currentPage ?? 0) + 1;
    await fetchNotifications(page: nextPage);
  }

  /// Mark a single notification as read
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
          
          // Update summary if available
          if (_summary != null) {
            _summary = NotificationSummary(
              total: _summary!.total,
              unread: _summary!.unread > 0 ? _summary!.unread - 1 : 0,
              read: _summary!.read + 1,
              byType: _summary!.byType,
              recentUnread: _summary!.recentUnread > 0 ? _summary!.recentUnread - 1 : 0,
            );
          }
          
          notifyListeners();
          
          print('✅ Notification $notificationId marked as read');
        }
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final success = await _repository.markAllAsRead();
      
      if (success) {
        // Update local state
        _notifications = _notifications.map((notification) {
          return notification.copyWith(
            isRead: true,
            readAt: DateTime.now().toIso8601String(),
          );
        }).toList();
        
        _unreadCount = 0;
        
        // Update summary if available
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
        
        print('✅ All notifications marked as read');
      }
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Set type filter
  void setTypeFilter(String? type) {
    if (_selectedType != type) {
      _selectedType = type;
      fetchNotifications(refresh: true);
    }
  }

  /// Set read status filter
  void setReadStatusFilter(bool? isRead) {
    if (_selectedReadStatus != isRead) {
      _selectedReadStatus = isRead;
      fetchNotifications(refresh: true);
    }
  }

  /// Clear all filters
  void clearFilters() {
    _selectedType = null;
    _selectedReadStatus = null;
    fetchNotifications(refresh: true);
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Handle notification click actions
  void handleNotificationClick(NotificationModel notification) {
    // Mark as read if not already read
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Handle click action based on notification data
    final clickAction = notification.data['click_action'] as String?;
    final leaveId = notification.data['leave_id'] as String?;
    
    print('🔔 Notification clicked: $clickAction, Leave ID: $leaveId');
    
    // Trigger navigation callback
    if (clickAction != null && onNavigationRequired != null) {
      onNavigationRequired!(clickAction, notification.data);
    }
  }

  /// Add a new notification (for real-time updates)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    
    if (!notification.isRead) {
      _unreadCount++;
    }
    
    // Update summary
    if (_summary != null) {
      final typeCount = _summary!.byType[notification.type] ?? 0;
      final updatedByType = Map<String, int>.from(_summary!.byType);
      updatedByType[notification.type] = typeCount + 1;
      
      _summary = NotificationSummary(
        total: _summary!.total + 1,
        unread: !notification.isRead ? _summary!.unread + 1 : _summary!.unread,
        read: notification.isRead ? _summary!.read + 1 : _summary!.read,
        byType: updatedByType,
        recentUnread: !notification.isRead ? _summary!.recentUnread + 1 : _summary!.recentUnread,
      );
    }
    
    notifyListeners();
    print('✅ New notification added: ${notification.title}');
  }

  /// Update notification status (for real-time updates)
  void updateNotification(NotificationModel updatedNotification) {
    final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
    if (index != -1) {
      final oldNotification = _notifications[index];
      _notifications[index] = updatedNotification;
      
      // Update unread count if read status changed
      if (oldNotification.isRead != updatedNotification.isRead) {
        if (updatedNotification.isRead && !oldNotification.isRead) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        } else if (!updatedNotification.isRead && oldNotification.isRead) {
          _unreadCount++;
        }
      }
      
      notifyListeners();
      print('✅ Notification updated: ${updatedNotification.title}');
    }
  }

  /// Remove notification
  void removeNotification(int notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications.removeAt(index);
      
      if (!notification.isRead) {
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      }
      
      // Update summary
      if (_summary != null) {
        final typeCount = _summary!.byType[notification.type] ?? 0;
        final updatedByType = Map<String, int>.from(_summary!.byType);
        if (typeCount > 1) {
          updatedByType[notification.type] = typeCount - 1;
        } else {
          updatedByType.remove(notification.type);
        }
        
        _summary = NotificationSummary(
          total: _summary!.total > 0 ? _summary!.total - 1 : 0,
          unread: !notification.isRead ? 
            (_summary!.unread > 0 ? _summary!.unread - 1 : 0) : 
            _summary!.unread,
          read: notification.isRead ? 
            (_summary!.read > 0 ? _summary!.read - 1 : 0) : 
            _summary!.read,
          byType: updatedByType,
          recentUnread: !notification.isRead ? 
            (_summary!.recentUnread > 0 ? _summary!.recentUnread - 1 : 0) : 
            _summary!.recentUnread,
        );
      }
      
      notifyListeners();
      print('✅ Notification removed: ${notification.title}');
    }
  }

  /// Get notifications by type
  List<NotificationModel> getNotificationsByType(String type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Get recent notifications (within last 24 hours)
  List<NotificationModel> getRecentNotifications() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((n) {
      try {
        final createdAt = DateTime.parse(n.createdAt);
        return createdAt.isAfter(yesterday);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchNotifications(refresh: true),
      fetchUnreadCount(),
    ]);
  }

  /// Reset all state
  void reset() {
    _notifications.clear();
    _unreadCount = 0;
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    _pagination = null;
    _summary = null;
    _selectedType = null;
    _selectedReadStatus = null;
    stopPeriodicUnreadCountUpdate();
    notifyListeners();
  }

  @override
  void dispose() {
    stopPeriodicUnreadCountUpdate();
    super.dispose();
  }
}