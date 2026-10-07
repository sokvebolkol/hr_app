import 'package:flutter/foundation.dart';

import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';

/// Owns the Announcement tab's unread badge.
///
/// Backed by `GET /messages/unread-count`, so the count is authoritative and
/// server-side rather than derived on the device.
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

  int get totalUnread => _totalUnread;
  List<AnnouncementChannel> get byChannel => List.unmodifiable(_byChannel);
  bool get hasUnread => _totalUnread > 0;

  /// Display string, e.g. "99+" past the ceiling.
  String get badgeText =>
      _totalUnread > maxBadgeCount ? '$maxBadgeCount+' : '$_totalUnread';

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

  /// Resets state on logout so the next user does not inherit a count.
  Future<void> reset() async {
    _totalUnread = 0;
    _byChannel = const [];
    notifyListeners();
  }
}
