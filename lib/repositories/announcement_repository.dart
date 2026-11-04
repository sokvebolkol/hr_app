import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/announcement_model.dart';
import '../models/team_join_request_model.dart';
import '../services/global_service.dart';
import '../services/http_service.dart';
import '../utils/exceptions.dart';

/// Read-only announcement feed backed by the Microsoft Teams bridge API,
/// plus per-user read/unread state held by the HR backend.
class AnnouncementRepository {
  final ServerService _serverService = ServerService();

  /// Teams whose channels make up the feed. The first is Chokchey Finance.
  static const List<String> teamIds = [
    // '23550c47-751a-4881-b59f-278ff7a8cb40',
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

  // ─────────────────────── Combined endpoints ───────────────────────────
  //
  // /announcements, /announcements/channels, /announcements/unread-count and
  // /announcements/read-all cover every team the user can see in one call.
  // A server that does not have them yet answers 404 on the first call; the
  // app then uses the per-team endpoints below for the rest of the launch.

  /// Per server: true = combined endpoints work, false = not deployed.
  static final Map<String, bool> _combinedApi = {};

  bool get _combinedUnavailable =>
      _combinedApi[_serverService.baseUrl] == false;

  /// True when this 404 means "route not deployed" (first call only). Once a
  /// combined call has succeeded, a 404 is a real error and is decoded.
  bool _markCombinedMissing(http.Response response) {
    final base = _serverService.baseUrl;
    if (response.statusCode == 404 && _combinedApi[base] != true) {
      _combinedApi[base] = false;
      return true;
    }
    _combinedApi[base] = true;
    return false;
  }

  /// GET on a combined endpoint. Null when the server does not have it.
  Future<Map<String, dynamic>?> _combinedGet(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    if (_combinedUnavailable) return null;
    final uri = Uri.parse(
      '${_serverService.baseUrl}announcements$path',
    ).replace(queryParameters: query.isEmpty ? null : query);
    final response = await HttpService.getAllowingErrors(
      url: uri.toString(),
      headers: await _headers(),
    );
    if (_markCombinedMissing(response)) return null;
    return _decode(response);
  }

  /// Learns channel → team from items that carry `team_id`.
  void _rememberTeams(List<Map<String, dynamic>> items, String channelKey) {
    for (final item in items) {
      final channelId = item[channelKey]?.toString() ?? '';
      final teamId = item['team_id']?.toString() ?? '';
      if (teamId.isNotEmpty) _remember(channelId, teamId);
    }
  }

  // ─────────────────────────── 1. Message list ───────────────────────────

  /// GET /announcements: one sorted, paginated list across all teams.
  /// Falls back to [_getMessagesPerTeam] when the server does not have it.
  Future<AnnouncementPage> getMessages({
    String? channelId,
    String status = 'all',
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final body = await _combinedGet('', {
      'status': status,
      'page': '$page',
      'per_page': '$perPage',
      if (channelId != null && channelId.isNotEmpty) 'channel_id': channelId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    if (body == null) {
      return _getMessagesPerTeam(
        channelId: channelId,
        status: status,
        search: search,
        page: page,
        perPage: perPage,
      );
    }

    return AnnouncementPage(
      items: _combinedMessages(_list(body)),
      meta: AnnouncementMeta.fromJson(_meta(body)),
    );
  }

  /// Items from the combined endpoints: learns each channel's team and
  /// marks `can_open_in_teams` as a confirmed membership result.
  List<AnnouncementMessage> _combinedMessages(List<Map<String, dynamic>> rows) {
    _rememberTeams(rows, 'channel_id');
    return rows.map((row) {
      final json = Map<String, dynamic>.from(row);
      json[AnnouncementMessage.canOpenVerifiedKey] =
          json['can_open_in_teams'] is bool;
      return AnnouncementMessage.fromJson(json);
    }).toList();
  }

  /// Parses the `announcements` block of `GET /notifications/overview`.
  /// Every part is optional; missing parts come back null or empty.
  AnnouncementOverview parseOverview(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(dynamic v) =>
        v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

    final items = json['items'];
    final meta = json['meta'];
    final page =
        items is List
            ? AnnouncementPage(
              items: _combinedMessages(maps(items)),
              meta: AnnouncementMeta.fromJson(
                meta is Map<String, dynamic> ? meta : null,
              ),
            )
            : null;

    final channelRows = maps(json['channels']);
    _rememberTeams(channelRows, 'id');
    final unreadRows = maps(json['unread_by_channel']);
    _rememberTeams(unreadRows, 'channel_id');

    final pending = json['pending_join_requests'];
    return AnnouncementOverview(
      firstPage: page,
      channels: channelRows.map(AnnouncementChannel.fromJson).toList(),
      unread: UnreadCountResult(
        totalUnread:
            json['unread'] is num
                ? (json['unread'] as num).toInt()
                : (page?.meta.unreadCount ?? 0),
        byChannel: unreadRows.map(AnnouncementChannel.fromJson).toList(),
      ),
      pendingJoinRequests: pending is num ? pending.toInt() : null,
    );
  }

  /// Fallback: GET /teams/{teamId}/messages
  ///
  /// [status] is `all`, `unread` or `read`. [channelId] filters to one
  /// channel; it contains `:` and `@` so it is URL-encoded by [Uri].
  ///
  /// Without a channel, page [page] is fetched from every team and merged
  /// newest first; the meta sums totals and keeps the furthest last page.
  Future<AnnouncementPage> _getMessagesPerTeam({
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

  /// GET /teams/{teamId}/channels/{channelId}/messages/{messageId}?mark_read=1
  ///
  /// Loads one post, e.g. the one a notification points to, and marks it
  /// read. When the response leaves out `channel_id` or `id`, they are
  /// filled from the arguments so the message can still be opened.
  Future<AnnouncementMessage> getMessage({
    required String teamId,
    required String channelId,
    required String messageId,
  }) async {
    final uri = Uri.parse(
      '${_base(teamId)}/channels/${Uri.encodeComponent(channelId)}'
      '/messages/$messageId',
    ).replace(queryParameters: const {'mark_read': '1'});

    final response = await HttpService.getAllowingErrors(
      url: uri.toString(),
      headers: await _headers(),
    );
    final body = _decode(response);
    final data = body['data'];
    final json = Map<String, dynamic>.from(
      data is Map<String, dynamic> ? data : body,
    );

    if ((json['channel_id']?.toString() ?? '').isEmpty) {
      json['channel_id'] = channelId;
    }
    if ((json['id']?.toString() ?? '').isEmpty) json['id'] = messageId;

    _remember(channelId, teamId);
    return AnnouncementMessage.fromJson(json);
  }

  // ────────────────────────── 2. Unread count ────────────────────────────

  /// GET /announcements/unread-count (all teams in one call), falling back
  /// to GET /teams/{teamId}/messages/unread-count summed across teams.
  Future<UnreadCountResult> getUnreadCount({String? channelId}) async {
    final query = <String, String>{
      if (channelId != null && channelId.isNotEmpty) 'channel_id': channelId,
    };

    final combined = await _combinedGet('/unread-count', query);
    if (combined != null) {
      final data = combined['data'];
      final json = data is Map<String, dynamic> ? data : combined;
      final byChannel = json['by_channel'];
      if (byChannel is List) {
        _rememberTeams(
          byChannel.whereType<Map<String, dynamic>>().toList(),
          'channel_id',
        );
      }
      return UnreadCountResult.fromJson(json);
    }

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

  // ───────────────────────────── 5. Read all ─────────────────────────────

  /// POST /announcements/read-all (all teams, or one channel), falling back
  /// to POST /teams/{teamId}/messages/read-all per team.
  Future<void> markAllRead({String? channelId}) async {
    final payload = <String, String>{
      if (channelId != null && channelId.isNotEmpty) 'channel_id': channelId,
    };
    if (!_combinedUnavailable) {
      final response = await http
          .post(
            Uri.parse('${_serverService.baseUrl}announcements/read-all'),
            headers: await _headers(),
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (!_markCombinedMissing(response)) {
        _decode(response);
        return;
      }
    }

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

  /// GET /announcements/channels (all teams in one call), falling back to
  /// GET /teams/{teamId}/channels per team. Used for the channel picker.
  Future<List<AnnouncementChannel>> getChannels() async {
    final combined = await _combinedGet('/channels');
    if (combined != null) {
      final rows = _list(combined);
      _rememberTeams(rows, 'id');
      return rows.map(AnnouncementChannel.fromJson).toList();
    }

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

/// Whether the signed-in user can see a post in Microsoft Teams.
enum TeamsAccess {
  /// Member of the post's team: open the Teams link.
  member,

  /// Not a member: Teams would open an empty channel ("No one has sent any
  /// messages yet"), so show "Request to join" instead.
  notMember,

  /// Could not be confirmed (membership not synced or endpoint missing):
  /// show the post in the app, which still offers "Open in Teams".
  unknown,
}

/// Team ids confirmed as "member" in this session, keyed with the server and
/// token so a different user or environment never reuses them. Only positive
/// results are cached, so a user who was just added is picked up next tap.
final Set<String> _confirmedTeamMembers = {};

extension TeamJoinRequestApi on AnnouncementRepository {
  // ───────────────────────── 7. Request to join ──────────────────────────

  Map<String, dynamic> _dataMap(Map<String, dynamic> body) {
    final data = body['data'];
    return data is Map<String, dynamic> ? data : const {};
  }

  /// The team owning [channelId] (learned from the feed).
  String teamIdForChannel(String channelId) => _teamFor(channelId);

  /// Decides what tapping [message] should do, based on a live
  /// `GET /teams/{teamId}/membership` check.
  ///
  /// The feed's `can_open_in_teams` is only trusted when it is `false`: the
  /// API also sends `true` (or nothing) when it does not know, and opening
  /// Teams for a non-member shows an empty channel instead of the post.
  Future<TeamsAccess> resolveTeamsAccess(AnnouncementMessage message) async {
    if (message.canOpenInTeamsFromApi == false) return TeamsAccess.notMember;
    // From GET /announcements the flag is already a confirmed result.
    if (message.canOpenInTeamsVerified &&
        message.canOpenInTeamsFromApi == true) {
      return TeamsAccess.member;
    }
    if (message.channelId.isEmpty) return TeamsAccess.unknown;

    try {
      final teamId = _teamFor(message.channelId);
      final key = '${_serverService.baseUrl}|${await _token()}|$teamId';
      if (_confirmedTeamMembers.contains(key)) return TeamsAccess.member;

      final membership = await getMembership(channelId: message.channelId);
      switch (membership.isMember) {
        case true:
          _confirmedTeamMembers.add(key);
          return TeamsAccess.member;
        case false:
          return TeamsAccess.notMember;
        default:
          return TeamsAccess.unknown;
      }
    } catch (e) {
      return TeamsAccess.unknown;
    }
  }

  /// GET /teams/{teamId}/membership
  Future<TeamMembership> getMembership({required String channelId}) async {
    final response = await HttpService.getAllowingErrors(
      url: '${_base(_teamFor(channelId))}/membership',
      headers: await _headers(),
    );
    return TeamMembership.fromJson(_dataMap(_decode(response)));
  }

  /// POST /teams/{teamId}/join-requests. Returns the new request, or the
  /// open one when the user already asked (no duplicate is created).
  Future<TeamJoinRequest> requestJoin({
    required String channelId,
    String? messageId,
    String? note,
  }) async {
    final response = await http
        .post(
          Uri.parse('${_base(_teamFor(channelId))}/join-requests'),
          headers: await _headers(),
          body: json.encode({
            'channel_id': channelId,
            if (messageId != null && RegExp(r'^\d{10,20}$').hasMatch(messageId))
              'message_id': messageId,
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));
    return TeamJoinRequest.fromJson(_dataMap(_decode(response)));
  }

  /// DELETE /teams/{teamId}/join-requests/{id} (own pending request only).
  Future<TeamJoinRequest> cancelJoinRequest(TeamJoinRequest request) async {
    final teamId =
        request.teamId.isNotEmpty
            ? request.teamId
            : _teamFor(request.channelId ?? '');
    final response = await http
        .delete(
          Uri.parse('${_base(teamId)}/join-requests/${request.id}'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return TeamJoinRequest.fromJson(_dataMap(_decode(response)));
  }

  /// GET /teams/join-requests/incoming: requests for teams the user owns.
  /// Empty for users who own no team.
  Future<List<TeamJoinRequest>> getIncomingJoinRequests({
    String status = TeamJoinRequest.pending,
  }) async {
    final uri = Uri.parse(
      '${_serverService.baseUrl}teams/join-requests/incoming',
    ).replace(queryParameters: {'status': status, 'per_page': '100'});
    final response = await HttpService.getAllowingErrors(
      url: uri.toString(),
      headers: await _headers(),
    );
    return _list(_decode(response)).map(TeamJoinRequest.fromJson).toList();
  }

  /// POST /teams/join-requests/{id}/approve or /reject. Returns the API's
  /// message, e.g. "Approved. The user will be added … within a few minutes."
  Future<String> decideJoinRequest({
    required int id,
    required bool approve,
    String? note,
  }) async {
    final response = await http
        .post(
          Uri.parse(
            '${_serverService.baseUrl}teams/join-requests/$id/'
            '${approve ? 'approve' : 'reject'}',
          ),
          headers: await _headers(),
          body: json.encode({
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _decode(response)['message']?.toString() ?? '';
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
