import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/announcement_model.dart';
import '../services/global_service.dart';
import '../services/http_service.dart';
import '../utils/exceptions.dart';

/// Read-only announcement feed backed by the Microsoft Teams bridge API,
/// plus per-user read/unread state held by the HR backend.
class AnnouncementRepository {
  final ServerService _serverService = ServerService();

  /// Teams whose channels make up the feed. The first is Chokchey Finance.
  static const List<String> teamIds = [
    '23550c47-751a-4881-b59f-278ff7a8cb40',
    '03bc38e3-7843-48d1-abd4-7d14b7d5fd7f',
  ];

  /// Which team owns each channel, learned from every channel, message and
  /// unread count fetched. Static so all repository instances share it.
  static final Map<String, String> _teamByChannel = {};

  String _base(String teamId) => '${_serverService.baseUrl}teams/$teamId';

  void _remember(String channelId, String teamId) {
    if (channelId.isNotEmpty) _teamByChannel[channelId] = teamId;
  }

  /// The team owning [channelId], or the first team if not yet known.
  String _teamFor(String channelId) =>
      _teamByChannel[channelId] ?? teamIds.first;

  /// Runs [call] against every team at once. A team that fails (e.g. the user
  /// is not a member) is skipped; the error is rethrown only if all fail.
  Future<List<T>> _acrossTeams<T>(
    Future<T> Function(String teamId) call,
  ) async {
    final ok = <T>[];
    Object? firstError;
    StackTrace? firstStack;
    await Future.wait(
      teamIds.map((teamId) async {
        try {
          ok.add(await call(teamId));
        } catch (e, st) {
          firstError ??= e;
          firstStack ??= st;
        }
      }),
    );
    if (ok.isEmpty && firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStack!);
    }
    return ok;
  }

  Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw UnauthorizedException(
        message: 'Session expired. Please login again.',
      );
    }
    return token;
  }

  Future<Map<String, String>> _headers() async => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await _token()}',
  };

  /// Decodes a response, turning API/HTTP errors into typed exceptions and
  /// preserving the backend's own `message`.
  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    Map<String, dynamic> body;
    try {
      body = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw DataParseException(message: 'Unexpected response from server.');
    }

    final ok = status >= 200 && status < 300 && body['success'] != false;
    if (ok) return body;

    final message = body['message']?.toString();
    switch (status) {
      case 401:
        throw UnauthorizedException(message: message);
      case 403:
        throw AnnouncementForbiddenException(message: message);
      case 404:
        throw NotFoundException(message: message);
      case 429:
        throw AnnouncementRateLimitedException(message: message);
      default:
        if (status >= 500) {
          throw ServerException(message: message, statusCode: status);
        }
        throw ClientException(
          message: message ?? 'Request failed ($status).',
          statusCode: status,
        );
    }
  }

  /// `data` may be the list itself or nested under `data.items`/`data.data`.
  List<Map<String, dynamic>> _list(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map) {
      for (final key in ['items', 'data', 'messages', 'channels', 'results']) {
        final inner = data[key];
        if (inner is List) {
          return inner.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    final root = body['items'];
    if (root is List) return root.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  Map<String, dynamic>? _meta(Map<String, dynamic> body) {
    final meta = body['meta'];
    if (meta is Map<String, dynamic>) return meta;
    final data = body['data'];
    if (data is Map && data['meta'] is Map<String, dynamic>) {
      return data['meta'] as Map<String, dynamic>;
    }
    return null;
  }

  // ─────────────────────────── 1. Message list ───────────────────────────

  /// GET /teams/{teamId}/messages
  ///
  /// [status] is `all`, `unread` or `read`. [channelId] filters to one
  /// channel; it contains `:` and `@` so it is URL-encoded by [Uri].
  ///
  /// Without a channel, page [page] is fetched from every team and merged
  /// newest first; the meta sums totals and keeps the furthest last page.
  Future<AnnouncementPage> getMessages({
    String? channelId,
    String status = 'all',
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final query = <String, String>{
      'status': status,
      'page': '$page',
      'per_page': '$perPage',
      if (channelId != null && channelId.isNotEmpty) 'channel_id': channelId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    Future<AnnouncementPage> fetch(String teamId) async {
      // Uri.replace percent-encodes the channel_id value for us.
      final uri = Uri.parse(
        '${_base(teamId)}/messages',
      ).replace(queryParameters: query);

      final response = await HttpService.getAllowingErrors(
        url: uri.toString(),
        headers: await _headers(),
      );
      final body = _decode(response);
      final items = _list(body).map(AnnouncementMessage.fromJson).toList();
      for (final m in items) {
        _remember(m.channelId, teamId);
      }
      return AnnouncementPage(
        items: items,
        meta: AnnouncementMeta.fromJson(_meta(body)),
      );
    }

    if (channelId != null && channelId.isNotEmpty) {
      return fetch(_teamFor(channelId));
    }

    final pages = await _acrossTeams(fetch);
    final items = [for (final p in pages) ...p.items]..sort((a, b) {
      final at = a.createdAt, bt = b.createdAt;
      if (at == null || bt == null) return at == null ? 1 : -1;
      return bt.compareTo(at);
    });
    return AnnouncementPage(
      items: items,
      meta: AnnouncementMeta(
        currentPage: page,
        lastPage: pages.fold(
          page,
          (max, p) => p.meta.lastPage > max ? p.meta.lastPage : max,
        ),
        total: pages.fold(0, (sum, p) => sum + p.meta.total),
        unreadCount: pages.fold(0, (sum, p) => sum + p.meta.unreadCount),
      ),
    );
  }

  // ────────────────────────── 2. Unread count ────────────────────────────

  /// GET /teams/{teamId}/messages/unread-count, summed across teams.
  Future<UnreadCountResult> getUnreadCount({String? channelId}) async {
    final query = <String, String>{
      if (channelId != null && channelId.isNotEmpty) 'channel_id': channelId,
    };

    Future<UnreadCountResult> fetch(String teamId) async {
      final uri = Uri.parse(
        '${_base(teamId)}/messages/unread-count',
      ).replace(queryParameters: query.isEmpty ? null : query);

      final response = await HttpService.getAllowingErrors(
        url: uri.toString(),
        headers: await _headers(),
      );
      final body = _decode(response);
      final data = body['data'];
      final result = UnreadCountResult.fromJson(
        data is Map<String, dynamic> ? data : body,
      );
      for (final c in result.byChannel) {
        _remember(c.id, teamId);
      }
      return result;
    }

    if (channelId != null && channelId.isNotEmpty) {
      return fetch(_teamFor(channelId));
    }

    final results = await _acrossTeams(fetch);
    return UnreadCountResult(
      totalUnread: results.fold(0, (sum, r) => sum + r.totalUnread),
      byChannel: [for (final r in results) ...r.byChannel],
    );
  }

  // ──────────────────────── 3/4. Read and unread ─────────────────────────

  Future<void> _postReadState({
    required String path,
    required String channelId,
    required List<String> messageIds,
  }) async {
    final response = await http
        .post(
          Uri.parse('${_base(_teamFor(channelId))}/messages/$path'),
          headers: await _headers(),
          body: json.encode({
            'channel_id': channelId,
            'message_ids': messageIds,
          }),
        )
        .timeout(const Duration(seconds: 15));
    _decode(response);
  }

  /// POST /teams/{teamId}/messages/read
  Future<void> markRead({
    required String channelId,
    required List<String> messageIds,
  }) => _postReadState(
    path: 'read',
    channelId: channelId,
    messageIds: messageIds,
  );

  /// POST /teams/{teamId}/messages/unread
  Future<void> markUnread({
    required String channelId,
    required List<String> messageIds,
  }) => _postReadState(
    path: 'unread',
    channelId: channelId,
    messageIds: messageIds,
  );

  // ───────────────────────────── 5. Read all ─────────────────────────────

  /// POST /teams/{teamId}/messages/read-all
  ///
  /// Sends `{channel_id: ...}` to the owning team to clear one channel, or
  /// `{}` to every team to clear all channels.
  Future<void> markAllRead({String? channelId}) async {
    Future<void> post(String teamId, Map<String, String> payload) async {
      final response = await http
          .post(
            Uri.parse('${_base(teamId)}/messages/read-all'),
            headers: await _headers(),
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));
      _decode(response);
    }

    if (channelId != null && channelId.isNotEmpty) {
      await post(_teamFor(channelId), {'channel_id': channelId});
      return;
    }
    await _acrossTeams((teamId) => post(teamId, {}));
  }

  // ───────────────────────────── 6. Channels ─────────────────────────────

  /// GET /teams/{teamId}/channels for every team — used for the filter
  /// chips.
  Future<List<AnnouncementChannel>> getChannels() async {
    final lists = await _acrossTeams((teamId) async {
      final response = await HttpService.getAllowingErrors(
        url: '${_base(teamId)}/channels',
        headers: await _headers(),
      );
      final body = _decode(response);
      final channels = _list(body).map(AnnouncementChannel.fromJson).toList();
      for (final c in channels) {
        _remember(c.id, teamId);
      }
      return channels;
    });
    return [for (final l in lists) ...l];
  }
}

/// 403 — the signed-in user cannot see this team or channel.
class AnnouncementForbiddenException extends AppException {
  AnnouncementForbiddenException({String? message})
    : super(
        message: message ?? 'You do not have access to this content.',
        prefix: 'No Access',
      );
}

/// 429 — rate limited; the caller should retry later.
class AnnouncementRateLimitedException extends AppException {
  AnnouncementRateLimitedException({String? message})
    : super(
        message: message ?? 'Too many requests. Please try again later.',
        prefix: 'Rate Limited',
      );
}
