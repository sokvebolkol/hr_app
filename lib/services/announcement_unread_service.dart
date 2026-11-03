import 'package:flutter/foundation.dart';

import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';

/// Owns the Announcement tab's unread badge.
///
/// Filled by the notification overview loaded with the Dashboard (see
/// `NotificationViewModel.loadAll`); [refresh] is the fallback when the
/// overview endpoint is not available.
class AnnouncementUnreadService extends ChangeNotifier {
  AnnouncementUnreadService._();
  static final AnnouncementUnreadService instance =
      AnnouncementUnreadService._();

  final AnnouncementRepository _repository = AnnouncementRepository();

  /// Ceiling so a noisy workspace cannot produce an absurd badge.
  static const int maxBadgeCount = 99;

  int _totalUnread = 0;
  List<AnnouncementChannel> _byChannel = const [];
  bool _isRefreshing = false;

  /// Goes up each time every announcement was marked read from outside the
  /// Announcement tab (the Notification screen's "Mark all as read"), so an
  /// open announcement list can mark its items read too.
  int _allReadVersion = 0;
  int get allReadVersion => _allReadVersion;

  int get totalUnread => _totalUnread;
  List<AnnouncementChannel> get byChannel => List.unmodifiable(_byChannel);
  /// Join requests waiting for this user as a team owner.
  int _pendingJoinRequests = 0;
  int get pendingJoinRequests => _pendingJoinRequests;

  /// Announcement tab badge: unread posts + waiting join requests, so the
  /// owner sees both in one number. [totalUnread] stays posts only (used
  /// by the channel picker).
  int get badgeCount => _totalUnread + _pendingJoinRequests;

  bool get hasUnread => badgeCount > 0;

  /// Display string, e.g. "99+" past the ceiling.
  String get badgeText =>
      badgeCount > maxBadgeCount ? '$maxBadgeCount+' : '$badgeCount';

  /// Updates the waiting join-request count (from the overview or from
  /// GET /teams/join-requests/incoming).
  void setPendingJoinRequests(int count) {
    final next = count < 0 ? 0 : count;
    if (_pendingJoinRequests == next) return;
    _pendingJoinRequests = next;
    notifyListeners();
  }

  int unreadForChannel(String channelId) {
    for (final channel in _byChannel) {
      if (channel.id == channelId) return channel.unread;
    }
    return 0;
  }

  /// Fetches the latest counts. Concurrent calls collapse into one.
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final result = await _repository.getUnreadCount();
      _totalUnread = result.totalUnread;
      _byChannel = result.byChannel;
      notifyListeners();
    } catch (e) {
      // The badge is advisory; never surface its failures as app errors.
      debugPrint('Announcement unread refresh failed: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// Applies counts that arrived with another response (e.g. the
  /// notification overview), so no separate request is needed.
  void apply(UnreadCountResult result) {
    _totalUnread = result.totalUnread;
    _byChannel = result.byChannel;
    notifyListeners();
  }

  /// Applies a known total immediately, e.g. from the message list's
  /// `meta.unread_count`, so the badge tracks the list without an extra
  /// round trip.
  void setTotal(int total) {
    if (_totalUnread == total) return;
    _totalUnread = total;
    notifyListeners();
  }

  /// Adjusts the badge after a local read/unread toggle.
  void applyDelta(int delta) {
    final next = _totalUnread + delta;
    _totalUnread = next < 0 ? 0 : next;
    notifyListeners();
  }

  /// Clears the badge, e.g. after "Mark all as read" across all channels.
  void clear() {
    if (_totalUnread == 0) return;
    _totalUnread = 0;
    _byChannel = const [];
    notifyListeners();
  }

  /// Every announcement in every team was marked read: clears the badge and
  /// tells open announcement lists (see [allReadVersion]).
  void markAllReadLocally() {
    _totalUnread = 0;
    _byChannel = const [];
    _allReadVersion++;
    notifyListeners();
  }

  /// Resets state on logout so the next user does not inherit a count.
  Future<void> reset() async {
    _totalUnread = 0;
    _byChannel = const [];
    _pendingJoinRequests = 0;
    notifyListeners();
  }
}
