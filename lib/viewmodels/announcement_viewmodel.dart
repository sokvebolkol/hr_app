import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/announcement_model.dart';
import '../repositories/announcement_repository.dart';
import '../services/announcement_unread_service.dart';
import '../utils/exceptions.dart';

/// Which tab the list is showing.
enum AnnouncementFilter { all, unread }

class AnnouncementViewModel extends ChangeNotifier {
  final AnnouncementRepository _repository = AnnouncementRepository();

  final List<AnnouncementMessage> _messages = [];
  List<AnnouncementChannel> _channels = [];
  AnnouncementMeta _meta = const AnnouncementMeta();

  AnnouncementFilter _filter = AnnouncementFilter.all;

  /// Null means the "All" chip.
  String? _channelId;
  String _search = '';
  Timer? _searchDebounce;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isMarkingAll = false;
  String? _errorMessage;
  bool _noAccess = false;
  bool _disposed = false;

  // Getters
  List<AnnouncementMessage> get messages => List.unmodifiable(_messages);
  List<AnnouncementChannel> get channels => List.unmodifiable(_channels);
  AnnouncementFilter get filter => _filter;
  String? get channelId => _channelId;
  String get search => _search;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get noAccess => _noAccess;
  int get unreadCount => _meta.unreadCount;
  bool get hasMore => _meta.hasMore;
  bool get isEmpty => !_isLoading && _messages.isEmpty && _errorMessage == null;

  String get _statusParam =>
      _filter == AnnouncementFilter.unread ? 'unread' : 'all';

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _describe(Object e) {
    if (e is AppException) return e.message;
    var message = e.toString();
    if (message.startsWith('Exception: ')) message = message.substring(11);
    return message;
  }

  // ───────────────────────────── Loading ──────────────────────────────

  /// Initial load: channels for the filter chips, then the first page.
  Future<void> initialize() async {
    await Future.wait([loadChannels(), load()]);
  }

  /// The feed shows top-level announcements only; thread replies are
  /// dropped.
  List<AnnouncementMessage> _postsOnly(List<AnnouncementMessage> items) =>
      items.where((m) => !m.isReply).toList();

  /// Roughly a phone screen of cards. Below this the list may not be
  /// scrollable, which would stop infinite scroll from ever triggering.
  static const int _minVisiblePosts = 10;

  /// Upper bound on consecutive reply-only pages skipped in one go.
  static const int _maxSkipPages = 5;

  /// After filtering out replies, fetch more pages if too few posts remain
  /// to fill the screen. Bounded so it can never loop indefinitely.
  Future<void> _topUpIfSparse() async {
    var attempts = 0;
    while (!_disposed &&
        _errorMessage == null &&
        _messages.length < _minVisiblePosts &&
        hasMore &&
        attempts < 3) {
      attempts++;
      await loadMore();
    }
  }

  Future<void> loadChannels() async {
    try {
      final fromApi = await _repository.getChannels();
      if (fromApi.isEmpty) {
        debugPrint(
          'Announcement channels: GET /channels returned no items; '
          'using channels found in messages instead.',
        );
      }
      // Messages may have loaded first (initialize runs both at once), so
      // keep any channels already discovered from them.
      final discovered = _channelsFromMessages();
      _channels = fromApi;
      _mergeChannels(discovered);
      _notify();
    } catch (e) {
      // The picker falls back to channels discovered from the messages.
      debugPrint('Announcement channels failed: $e');
    }
  }

  /// Channels referenced by the loaded messages. Every message carries its
  /// `channel_id` and `channel_name`, so this keeps the channel picker
  /// populated even if `GET /channels` fails or returns an unexpected shape.
  List<AnnouncementChannel> _channelsFromMessages() => _messages
      .map((m) => AnnouncementChannel(id: m.channelId, name: m.channelName))
      .toList();

  /// Adds channels not already known. Channels from the API keep their
  /// order; newly discovered ones are appended sorted by name.
  void _mergeChannels(Iterable<AnnouncementChannel> incoming) {
    final known = {for (final c in _channels) c.id};
    final added = <String, AnnouncementChannel>{};
    for (final c in incoming) {
      if (c.id.isEmpty || c.name.trim().isEmpty) continue;
      if (known.contains(c.id) || added.containsKey(c.id)) continue;
      added[c.id] = c;
    }
    if (added.isEmpty) return;
    final sorted =
        added.values.toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    _channels = [..._channels, ...sorted];
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _noAccess = false;
    _notify();

    try {
      final page = await _repository.getMessages(
        channelId: _channelId,
        status: _statusParam,
        search: _search,
        page: 1,
      );
      _messages
        ..clear()
        ..addAll(_postsOnly(page.items));
      _meta = page.meta;
      _mergeChannels(_channelsFromMessages());
      _syncBadge();
    } catch (e) {
      _errorMessage = _describe(e);
      _noAccess = e is AnnouncementForbiddenException;
    } finally {
      _isLoading = false;
      _notify();
    }
    await _topUpIfSparse();
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    _notify();
    try {
      final page = await _repository.getMessages(
        channelId: _channelId,
        status: _statusParam,
        search: _search,
        page: 1,
      );
      _messages
        ..clear()
        ..addAll(_postsOnly(page.items));
      _meta = page.meta;
      _mergeChannels(_channelsFromMessages());
      _errorMessage = null;
      _noAccess = false;
      _syncBadge();
      // Keep chip counts fresh too.
      unawaited(AnnouncementUnreadService.instance.refresh());
    } catch (e) {
      _errorMessage = _describe(e);
      _noAccess = e is AnnouncementForbiddenException;
    } finally {
      _isRefreshing = false;
      _notify();
    }
    await _topUpIfSparse();
  }

  /// Appends the next page (page-based infinite scroll).
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    _notify();
    try {
      // A page holding only replies adds nothing visible, and with no new
      // content the scroll listener never fires again, so the list would
      // stall. Keep fetching (bounded) until at least one post arrives.
      var added = 0;
      var fetched = 0;
      do {
        final page = await _repository.getMessages(
          channelId: _channelId,
          status: _statusParam,
          search: _search,
          page: _meta.currentPage + 1,
        );
        final posts = _postsOnly(page.items);
        _messages.addAll(posts);
        _meta = page.meta;
        added += posts.length;
        fetched++;
      } while (added == 0 && hasMore && fetched < _maxSkipPages && !_disposed);
      _mergeChannels(_channelsFromMessages());
    } catch (e) {
      _errorMessage = _describe(e);
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }

  /// Mirrors the list's `meta.unread_count` onto the shared badge.
  void _syncBadge() {
    // Only authoritative when looking at every channel with no search.
    if (_channelId == null && _search.trim().isEmpty) {
      AnnouncementUnreadService.instance.setTotal(_meta.unreadCount);
    }
  }

  // ──────────────────────────── Filtering ─────────────────────────────

  void setChannel(String? channelId) {
    if (_channelId == channelId) return;
    _channelId = channelId;
    _notify();
    load();
  }

  // ─────────────────────────── Read state ─────────────────────────────

  /// Marks one message read and updates the list in place, without a
  /// reload. Called when a message is opened.
  Future<void> markRead(AnnouncementMessage message) async {
    if (message.isRead) return;

    _applyReadState(message.id, true);
    AnnouncementUnreadService.instance.applyDelta(-1);

    try {
      await _repository.markRead(
        channelId: message.channelId,
        messageIds: [message.id],
      );
    } catch (e) {
      // Roll back so the UI never claims a state the server rejected.
      _applyReadState(message.id, false);
      AnnouncementUnreadService.instance.applyDelta(1);
      _errorMessage = _describe(e);
      _notify();
    }
  }

  /// Long-press action: mark a message unread again.
  Future<void> markUnread(AnnouncementMessage message) async {
    if (!message.isRead) return;

    _applyReadState(message.id, false);
    AnnouncementUnreadService.instance.applyDelta(1);

    try {
      await _repository.markUnread(
        channelId: message.channelId,
        messageIds: [message.id],
      );
      // In the Unread tab the message now belongs in the list; in other
      // views it simply restyles.
    } catch (e) {
      _applyReadState(message.id, true);
      AnnouncementUnreadService.instance.applyDelta(-1);
      _errorMessage = _describe(e);
      _notify();
    }
  }

  /// "Mark all as read" for the current channel, or every channel when the
  /// "All" chip is selected.
  Future<bool> markAllRead() async {
    _isMarkingAll = true;
    _notify();
    try {
      await _repository.markAllRead(channelId: _channelId);

      for (var i = 0; i < _messages.length; i++) {
        if (!_messages[i].isRead) {
          _messages[i] = _messages[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      _meta = AnnouncementMeta(
        currentPage: _meta.currentPage,
        lastPage: _meta.lastPage,
        total: _meta.total,
        unreadCount: 0,
      );

      if (_channelId == null) {
        AnnouncementUnreadService.instance.clear();
      } else {
        await AnnouncementUnreadService.instance.refresh();
      }

      // The Unread tab should now be empty, so reload to reflect that.
      if (_filter == AnnouncementFilter.unread) {
        await load();
      }
      return true;
    } catch (e) {
      _errorMessage = _describe(e);
      return false;
    } finally {
      _isMarkingAll = false;
      _notify();
    }
  }

  /// Flips one message's read flag in place and nudges the local unread
  /// count by one, so the list updates without a reload.
  void _applyReadState(String messageId, bool isRead) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    // No-op if it is already in the requested state, so the count stays
    // correct when this is called twice (e.g. rollback after an error).
    if (_messages[index].isRead == isRead) return;

    _messages[index] = _messages[index].copyWith(
      isRead: isRead,
      readAt: isRead ? DateTime.now() : null,
    );

    final delta = isRead ? -1 : 1;
    final nextUnread = _meta.unreadCount + delta;
    _meta = AnnouncementMeta(
      currentPage: _meta.currentPage,
      lastPage: _meta.lastPage,
      total: _meta.total,
      unreadCount: nextUnread < 0 ? 0 : nextUnread,
    );
    _notify();
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }
}
