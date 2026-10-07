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

  /// Chokchey Finance. Fixed because the feed is a single company team.
  static const String teamId = '23550c47-751a-4881-b59f-278ff7a8cb40';

  String get _base => '${_serverService.baseUrl}teams/$teamId';

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

    // Uri.replace percent-encodes the channel_id value for us.
    final uri = Uri.parse('$_base/messages').replace(queryParameters: query);

    final response = await HttpService.getAllowingErrors(
      url: uri.toString(),
      headers: await _headers(),
    );
    final body = _decode(response);

    return AnnouncementPage(
      items: _list(body).map(AnnouncementMessage.fromJson).toList(),
      meta: AnnouncementMeta.fromJson(_meta(body)),
    );
  }

  // ────────────────────────── 2. Unread count ────────────────────────────

  /// GET /teams/{teamId}/messages/unread-count
  Future<UnreadCountResult> getUnreadCount({String? channelId}) async {
    final query = <String, String>{
      if (channelId != null && channelId.isNotEmpty) 'channel_id': channelId,
    };
    final uri = Uri.parse(
      '$_base/messages/unread-count',
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await HttpService.getAllowingErrors(
      url: uri.toString(),
      headers: await _headers(),
    );
    final body = _decode(response);
    final data = body['data'];
    return UnreadCountResult.fromJson(
      data is Map<String, dynamic> ? data : body,
    );
  }

  // ──────────────────────── 3/4. Read and unread ─────────────────────────

  Future<void> _postReadState({
    required String path,
    required String channelId,
    required List<String> messageIds,
  }) async {
    final response = await http.post(
      Uri.parse('$_base/messages/$path'),
      headers: await _headers(),
      body: json.encode({
        'channel_id': channelId,
        'message_ids': messageIds,
      }),
    );
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
  /// Sends `{channel_id: ...}` to clear one channel, or `{}` for every
  /// channel.
  Future<void> markAllRead({String? channelId}) async {
    final response = await http.post(
      Uri.parse('$_base/messages/read-all'),
      headers: await _headers(),
      body: json.encode(
        channelId == null || channelId.isEmpty ? {} : {'channel_id': channelId},
      ),
    );
    _decode(response);
  }

  // ───────────────────────────── 6. Channels ─────────────────────────────

  /// GET /teams/{teamId}/channels — used for the filter chips.
  Future<List<AnnouncementChannel>> getChannels() async {
    final response = await HttpService.getAllowingErrors(
      url: '$_base/channels',
      headers: await _headers(),
    );
    final body = _decode(response);
    return _list(body).map(AnnouncementChannel.fromJson).toList();
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
