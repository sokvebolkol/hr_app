/// Models for the Announcement feed (Microsoft Teams bridge).
///
/// Read state is per user inside the HR app and is NOT synced back to the
/// Microsoft Teams app.

int _toInt(dynamic v, [int fallback = 0]) =>
    v is int ? v : int.tryParse(v?.toString() ?? '') ?? fallback;

/// Null for null, empty or whitespace-only values.
String? _nonEmpty(dynamic v) {
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

/// `meta` for the paginated message list.
class AnnouncementMeta {
  final int currentPage;
  final int lastPage;
  final int total;
  final int unreadCount;

  const AnnouncementMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.unreadCount = 0,
  });

  factory AnnouncementMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AnnouncementMeta();
    return AnnouncementMeta(
      currentPage: _toInt(json['current_page'], 1),
      lastPage: _toInt(json['last_page'], 1),
      total: _toInt(json['total']),
      unreadCount: _toInt(json['unread_count']),
    );
  }

  bool get hasMore => currentPage < lastPage;
}

/// A channel, used for the filter chips.
class AnnouncementChannel {
  final String id;
  final String name;

  /// Populated from the unread-count endpoint's `by_channel`.
  final int unread;

  const AnnouncementChannel({
    required this.id,
    required this.name,
    this.unread = 0,
  });

  factory AnnouncementChannel.fromJson(Map<String, dynamic> json) =>
      AnnouncementChannel(
        id: json['id']?.toString() ?? json['channel_id']?.toString() ?? '',
        name:
            json['name']?.toString() ??
            json['channel_name']?.toString() ??
            json['display_name']?.toString() ??
            '',
        unread: _toInt(json['unread']),
      );

  AnnouncementChannel copyWith({int? unread}) =>
      AnnouncementChannel(id: id, name: name, unread: unread ?? this.unread);
}

/// Result of GET /messages/unread-count.
class UnreadCountResult {
  final int totalUnread;
  final List<AnnouncementChannel> byChannel;

  const UnreadCountResult({this.totalUnread = 0, this.byChannel = const []});

  factory UnreadCountResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UnreadCountResult();
    return UnreadCountResult(
      totalUnread: _toInt(json['total_unread']),
      byChannel:
          _mapList(json['by_channel']).map(AnnouncementChannel.fromJson).toList(),
    );
  }
}

class MessageContent {
  /// "html" or "text".
  final String type;

  /// Raw HTML body, rendered by the detail screen.
  final String raw;

  /// Plain-text rendition, preferred for list previews.
  final String text;

  const MessageContent({this.type = 'text', this.raw = '', this.text = ''});

  factory MessageContent.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MessageContent();
    return MessageContent(
      type: json['type']?.toString() ?? 'text',
      raw: json['raw']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }

  /// Plain text for previews. Falls back to stripping [raw] when the API
  /// only supplies HTML.
  String get preview {
    if (text.trim().isNotEmpty) return text.trim();
    if (raw.trim().isEmpty) return '';
    return raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'</(p|div|li|h[1-6])>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class MessageAttachment {
  final String id;
  final String name;
  final String? contentType;
  final String? contentUrl;

  const MessageAttachment({
    this.id = '',
    this.name = '',
    this.contentType,
    this.contentUrl,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        id: json['id']?.toString() ?? '',
        name:
            json['name']?.toString() ??
            json['file_name']?.toString() ??
            'Attachment',
        contentType:
            json['content_type']?.toString() ?? json['contentType']?.toString(),
        contentUrl:
            json['content_url']?.toString() ?? json['contentUrl']?.toString(),
      );
}

class MessageReaction {
  final String type;
  final int count;

  const MessageReaction({this.type = '', this.count = 0});

  factory MessageReaction.fromJson(Map<String, dynamic> json) =>
      MessageReaction(
        type:
            json['type']?.toString() ??
            json['reaction_type']?.toString() ??
            '',
        count: _toInt(json['count'], 1),
      );

  /// Parses the API's `reactions` field.
  ///
  /// The backend sends an emoji-to-count map, e.g. `{"✍️": 4, "❤️": 1}`,
  /// but PHP encodes an empty map as `[]`. Both shapes are accepted, as is a
  /// list of `{type, count}` objects in case the format changes.
  static List<MessageReaction> parseAll(dynamic raw) {
    if (raw is Map) {
      return raw.entries
          .map(
            (e) => MessageReaction(type: '${e.key}', count: _toInt(e.value, 1)),
          )
          .where((r) => r.type.isNotEmpty)
          .toList();
    }
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(MessageReaction.fromJson)
          .toList();
    }
    return const [];
  }

  /// The API already keys reactions by emoji, so [type] is shown as-is.
  /// Named reactions from Teams' older vocabulary are mapped as a fallback.
  String get emoji {
    switch (type.toLowerCase()) {
      case 'like':
        return '\u{1F44D}';
      case 'heart':
      case 'love':
        return '❤️';
      case 'laugh':
        return '\u{1F604}';
      case 'surprised':
        return '\u{1F62E}';
      case 'sad':
        return '\u{1F622}';
      case 'angry':
        return '\u{1F620}';
      default:
        return type;
    }
  }

  /// e.g. "✍️ 4".
  String get label => '$emoji $count';
}

/// Someone @mentioned in the message body.
class MessageMention {
  final String name;
  final String? userId;

  const MessageMention({required this.name, this.userId});

  factory MessageMention.fromJson(Map<String, dynamic> json) => MessageMention(
    name: json['name']?.toString() ?? json['text']?.toString() ?? '',
    userId: json['user_id']?.toString(),
  );
}

/// Reads a list field defensively. PHP encodes an empty array as `[]` but an
/// associative one as `{}`, so a map is treated as its values.
List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is List) return raw.whereType<Map<String, dynamic>>().toList();
  if (raw is Map) return raw.values.whereType<Map<String, dynamic>>().toList();
  return const [];
}

/// One announcement (a Teams channel message).
class AnnouncementMessage {
  final String id;
  final String channelId;
  final String channelName;
  final String senderName;
  final DateTime? createdAt;
  final MessageContent content;
  final String? webUrl;
  final List<MessageAttachment> attachments;
  final List<MessageReaction> reactions;
  final List<MessageMention> mentions;
  final bool isRead;
  final DateTime? readAt;
  final String? subject;

  /// "normal", "high" or "urgent" (Teams message importance).
  final String importance;
  final DateTime? lastEditedAt;
  final DateTime? deletedAt;

  /// Id of the post this message replies to; null for a top-level post.
  /// Mirrors Microsoft Teams' `replyToId`, which is only set on replies.
  final String? replyToId;

  const AnnouncementMessage({
    required this.id,
    this.channelId = '',
    this.channelName = '',
    this.senderName = '',
    this.createdAt,
    this.content = const MessageContent(),
    this.webUrl,
    this.attachments = const [],
    this.reactions = const [],
    this.mentions = const [],
    this.isRead = false,
    this.readAt,
    this.subject,
    this.importance = 'normal',
    this.lastEditedAt,
    this.deletedAt,
    this.replyToId,
  });

  factory AnnouncementMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    final content = json['content'];
    return AnnouncementMessage(
      id: json['id']?.toString() ?? '',
      channelId: json['channel_id']?.toString() ?? '',
      channelName: json['channel_name']?.toString() ?? '',
      senderName:
          sender is Map
              ? (sender['name']?.toString() ?? '')
              : (sender?.toString() ?? ''),
      createdAt: _toDate(json['created_at']),
      content: MessageContent.fromJson(
        content is Map<String, dynamic> ? content : null,
      ),
      webUrl: json['web_url']?.toString(),
      attachments:
          _mapList(json['attachments']).map(MessageAttachment.fromJson).toList(),
      reactions: MessageReaction.parseAll(json['reactions']),
      mentions:
          _mapList(json['mentions']).map(MessageMention.fromJson).toList(),
      isRead: json['is_read'] == true,
      readAt: _toDate(json['read_at']),
      subject: json['subject']?.toString(),
      importance: json['importance']?.toString() ?? 'normal',
      lastEditedAt: _toDate(json['last_edited_at']),
      deletedAt: _toDate(json['deleted_at']),
      replyToId: _nonEmpty(json['reply_to_id']),
    );
  }

  /// Used for optimistic read/unread updates so the list does not reload.
  AnnouncementMessage copyWith({bool? isRead, DateTime? readAt}) =>
      AnnouncementMessage(
        id: id,
        channelId: channelId,
        channelName: channelName,
        senderName: senderName,
        createdAt: createdAt,
        content: content,
        webUrl: webUrl,
        attachments: attachments,
        reactions: reactions,
        mentions: mentions,
        isRead: isRead ?? this.isRead,
        readAt: isRead == false ? null : (readAt ?? this.readAt),
        subject: subject,
        importance: importance,
        lastEditedAt: lastEditedAt,
        deletedAt: deletedAt,
        replyToId: replyToId,
      );

  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasReactions => reactions.isNotEmpty;
  bool get isEdited => lastEditedAt != null;

  /// True for a reply in a thread rather than a top-level announcement.
  bool get isReply => replyToId != null;
  bool get isImportant =>
      importance.toLowerCase() == 'high' || importance.toLowerCase() == 'urgent';

  /// Inline images are Microsoft Graph `hostedContents` URLs that need a
  /// Graph token, so the app cannot display them; the UI shows a
  /// placeholder pointing to Teams instead.
  bool get hasInlineImages =>
      RegExp(r'<img\b', caseSensitive: false).hasMatch(content.raw);

  /// Reactions as "✍️ 4  ❤️ 1".
  String get reactionsLabel => reactions.map((r) => r.label).join('  ');

  String get senderInitial =>
      senderName.trim().isEmpty ? '?' : senderName.trim()[0].toUpperCase();

  /// Title line: the subject when present, otherwise the channel name.
  String get title =>
      (subject != null && subject!.trim().isNotEmpty)
          ? subject!.trim()
          : channelName;
}

/// A page of announcements plus its meta.
class AnnouncementPage {
  final List<AnnouncementMessage> items;
  final AnnouncementMeta meta;

  const AnnouncementPage({required this.items, required this.meta});
}
