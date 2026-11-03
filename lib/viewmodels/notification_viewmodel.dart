import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/notification_repository.dart';
import '../services/announcement_feed_cache.dart';
import '../services/announcement_unread_service.dart';

/// Single source of truth for notifications (HR list + counts) and the
/// combined unread badge (HR + announcements).
///
/// The Dashboard calls [loadAll] once when it opens: one request to
/// `GET /notifications/overview` fills the HR list, the announcement first
/// page and every unread count. The Notification screen and the
/// Announcement tab then reuse that data instead of fetching it again.
/// The 2-minute poll ([refreshCounts]) only asks for counts.
class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel() {
    // The bell shows HR + announcement unread, so follow both.
    AnnouncementUnreadService.instance.addListener(notifyListeners);
  }

  final NotificationRepository _repository = NotificationRepository();
  final AnnouncementRepository _announcementRepository =
      AnnouncementRepository();

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

  /// Unread count for the Home bell.
  ///
  /// Taken from the backend as is (`unread_count` /
  /// `unread.notifications`). That count already includes the
  /// announcement notifications, so the Teams unread count is NOT added on
  /// top (adding it counted each announcement twice).
  int get totalUnread => _unreadCount;

  /// Bell badge text, capped at "99+".
  String get totalUnreadText => totalUnread > 99 ? '99+' : '$totalUnread';

  // ───────────────────── Overview (one call for everything) ─────────────────

  /// How long loaded data counts as current, so opening the Notification
  /// screen right after the Dashboard does not fetch it again.
  static const Duration _freshFor = Duration(seconds: 60);

  Future<void>? _loadAllInFlight;
  DateTime? _loadedAt;
  String? _loadedForToken;
  bool _countsInFlight = false;

  /// Bumped by local read changes (mark one / mark all). A load or count
  /// request that started before the change answers with the old state, so
  /// its result is dropped instead of bringing the old unread count back.
  int _readStateVersion = 0;

  Future<String?> _currentToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return (token == null || token.isEmpty) ? null : token;
  }

  bool _isFreshFor(String token) =>
      _loadedForToken == token &&
      _loadedAt != null &&
      DateTime.now().difference(_loadedAt!) < _freshFor;

  void _markLoaded(String token) {
    _loadedForToken = token;
    _loadedAt = DateTime.now();
  }

  /// Another user logged in: drop the previous user's data before loading.
  void _resetIfUserChanged(String token) {
    if (_loadedForToken == null || _loadedForToken == token) return;
    _notifications = [];
    _pagination = null;
    _summary = null;
    _unreadCount = 0;
    _loadedAt = null;
    _loadedForToken = null;
    AnnouncementFeedCache.instance.clear();
    notifyListeners();
  }

  /// Loads all notification data (HR list, announcements, unread counts).
  /// Called by the Dashboard when it opens.
  ///
  /// Concurrent calls share one request, and data loaded within the last
  /// 60 seconds is reused unless [force] is true. Falls back to the older
  /// endpoints when the server has no `/notifications/overview` yet.
  Future<void> loadAll({bool force = false}) {
    final running = _loadAllInFlight;
    if (running != null) return running;
    final future = _loadAll(force);
    _loadAllInFlight = future;
    return future.whenComplete(() {
      if (identical(_loadAllInFlight, future)) _loadAllInFlight = null;
    });
  }

  Future<void> _loadAll(bool force) async {
    final token = await _currentToken();
    if (token == null) return; // not logged in
    _resetIfUserChanged(token);
    if (!force && _isFreshFor(token)) return;

    final version = _readStateVersion;
    try {
      final data = await _repository.getOverview();
      if (data != null) {
        if (version != _readStateVersion) return; // stale, see above
        _applyOverview(data, countsOnly: false);
        _markLoaded(token);
        return;
      }
    } catch (e) {
      debugPrint('Notification overview failed: $e');
    }

    // Older server: same data from the separate endpoints, in parallel.
    await Future.wait([
      fetchNotifications(refresh: true),
      AnnouncementUnreadService.instance.refresh(),
    ]);
    if (_error == null) _markLoaded(token);
  }

  /// Used by the Notification screen: reuses the data the Dashboard loaded
  /// when it is still fresh, otherwise loads the HR list.
  Future<void> ensureLoaded() async {
    final running = _loadAllInFlight;
    if (running != null) await running;

    final token = await _currentToken();
    if (token == null) return;
    _resetIfUserChanged(token);
    if (_isFreshFor(token) && _notifications.isNotEmpty) return;

    await fetchNotifications(refresh: true);
    if (_error == null) _markLoaded(token);
  }

  /// Unread counts only (the 2-minute poll and app resume).
  ///
  /// [force] runs even if a poll is in flight; used right after a local
  /// change so the server's new counts are confirmed (the older in-flight
  /// poll is ignored by the version check).
  Future<void> refreshCounts({bool force = false}) async {
    if (!force && (_countsInFlight || _loadAllInFlight != null)) return;
    final version = _readStateVersion;
    _countsInFlight = true;
    try {
      final data = await _repository.getOverview(countsOnly: true);
      if (data != null) {
        if (version == _readStateVersion) {
          _applyOverview(data, countsOnly: true);
        }
        return;
      }
    } catch (e) {
      debugPrint('Notification counts failed: $e');
    } finally {
      _countsInFlight = false;
    }

    // Older server: separate count endpoints.
    await Future.wait([
      fetchUnreadCount(),
      AnnouncementUnreadService.instance.refresh(),
    ]);
  }

  /// Applies `GET /notifications/overview` data:
  /// `unread` {notifications, announcements, total},
  /// `notifications` {notifications, pagination, summary} (same shape as
  /// /notifications/with-details), and `announcements` {items, meta,
  /// channels, unread, unread_by_channel, pending_join_requests}.
  void _applyOverview(Map<String, dynamic> data, {required bool countsOnly}) {
    final unread = data['unread'];
    int? countOf(String key) =>
        unread is Map && unread[key] is num
            ? (unread[key] as num).toInt()
            : null;

    final hr = data['notifications'];
    if (!countsOnly && hr is Map<String, dynamic>) {
      final response = NotificationResponse.fromJson({'data': hr});
      _notifications = response.notifications;
      _pagination = response.pagination;
      _summary = response.summary;
      _unreadCount = response.summary.unread;
      _error = null;
    }
    _unreadCount = countOf('notifications') ?? _unreadCount;

    final announcements = data['announcements'];
    if (announcements is Map<String, dynamic>) {
      final overview = _announcementRepository.parseOverview(announcements);
      var counts = overview.unread;
      final total = countOf('announcements');
      if (announcements['unread'] is! num && total != null) {
        counts = UnreadCountResult(
          totalUnread: total,
          byChannel: counts.byChannel,
        );
      }
      AnnouncementUnreadService.instance.apply(counts);
      // Join requests share the Announcement tab badge. Sent in the full
      // overview (and in counts_only if the backend includes it).
      final pending = overview.pendingJoinRequests;
      if (pending != null) {
        AnnouncementUnreadService.instance.setPendingJoinRequests(pending);
      }
      if (!countsOnly) AnnouncementFeedCache.instance.store(overview);
    } else {
      final total = countOf('announcements');
      if (total != null) AnnouncementUnreadService.instance.setTotal(total);
    }

    notifyListeners();
  }

  // Filter states
  String? _selectedType;
  bool? _selectedReadStatus;

  // Unread-count polling. One timer only; a tick is skipped while the
  // previous request is still running; polling pauses in background.
  static const Duration _pollInterval = Duration(minutes: 2);
  Timer? _timer;
  bool _pollingRequested = false;
  bool _unreadInFlight = false;
  bool _observingLifecycle = false;
  late final _NotificationLifecycleObserver _lifecycleObserver =
      _NotificationLifecycleObserver(this);

  /// Starts polling (idempotent): counts every 2 minutes. No fetch now,
  /// because the Dashboard loads everything with [loadAll] when it opens.
  void startPeriodicUnreadCountUpdate() {
    _pollingRequested = true;
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
      _observingLifecycle = true;
    }
    _startTimer(fetchNow: false);
  }

  void stopPeriodicUnreadCountUpdate() {
    _pollingRequested = false;
    _timer?.cancel();
    _timer = null;
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(_lifecycleObserver);
      _observingLifecycle = false;
    }
  }

  void _startTimer({required bool fetchNow}) {
    _timer?.cancel(); // never more than one timer
    if (fetchNow) refreshCounts();
    _timer = Timer.periodic(_pollInterval, (_) => refreshCounts());
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    if (!_pollingRequested) return;
    if (state == AppLifecycleState.resumed) {
      if (_timer == null) _startTimer(fetchNow: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> fetchUnreadCount() async {
    if (_unreadInFlight) return; // previous call still running
    _unreadInFlight = true;
    try {
      final response = await _repository.getUnreadCount();
      _unreadCount = response.unreadCount;
      notifyListeners();
    } catch (e) {
      // Don't show error to user for background updates
    } finally {
      _unreadInFlight = false;
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
    _readStateVersion++;
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

  /// "Mark all as read" for every tab: HR notifications (Personal / Staff
  /// Member / Notifications) and announcements in every team, in parallel.
  /// Each part that succeeds is applied; returns true only if both did.
  Future<bool> markAllAsRead() async {
    _readStateVersion++; // ignore loads/polls started before this
    try {
      final results = await Future.wait([
        _repository.markAllAsRead(),
        _markAllAnnouncementsRead(),
      ]);
      final success = results[0];
      final announcementsOk = results[1];

      if (announcementsOk) {
        // The cached first page still has unread items: never hand it over
        AnnouncementFeedCache.instance.clear();
        AnnouncementUnreadService.instance.markAllReadLocally();
      }

      if (!success) {
        notifyListeners();
        return false;
      }

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
              // Keep attendance data so these cards still open afterwards.
              staffAttendanceAdjustmentData:
                  notification.staffAttendanceAdjustmentData,
              ownAttendanceAdjustmentData:
                  notification.ownAttendanceAdjustmentData,
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
      // Confirm with the server (also picks up anything that arrived meanwhile)
      _readStateVersion++; // results requested before now are stale
      unawaited(refreshCounts(force: true));
      return announcementsOk;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// POST /announcements/read-all (every team). A user who cannot read any
  /// announcement team (403) has nothing to mark, which counts as done.
  Future<bool> _markAllAnnouncementsRead() async {
    try {
      await _announcementRepository.markAllRead();
      return true;
    } on AnnouncementForbiddenException {
      return true;
    } catch (e) {
      debugPrint('Mark all announcements read failed: $e');
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
    AnnouncementUnreadService.instance.removeListener(notifyListeners);
    super.dispose();
  }
}

class _NotificationLifecycleObserver with WidgetsBindingObserver {
  _NotificationLifecycleObserver(this._owner);
  final NotificationViewModel _owner;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _owner._onLifecycleChanged(state);
  }
}
