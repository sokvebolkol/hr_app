
class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final String category;
  final Map<String, dynamic> data;
  final bool isRead;
  final String? readAt;
  final String createdAt;
  final String timeAgo;
  final bool isRecent;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.category,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.timeAgo,
    required this.isRecent,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      data: json['data'] ?? {},
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'],
      createdAt: json['created_at'] ?? '',
      timeAgo: json['time_ago'] ?? '',
      isRecent: json['is_recent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'category': category,
      'data': data,
      'is_read': isRead,
      'read_at': readAt,
      'created_at': createdAt,
      'time_ago': timeAgo,
      'is_recent': isRecent,
    };
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    String? category,
    Map<String, dynamic>? data,
    bool? isRead,
    String? readAt,
    String? createdAt,
    String? timeAgo,
    bool? isRecent,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      category: category ?? this.category,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      timeAgo: timeAgo ?? this.timeAgo,
      isRecent: isRecent ?? this.isRecent,
    );
  }
}

class NotificationPagination {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMorePages;

  NotificationPagination({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasMorePages,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
      hasMorePages: json['has_more_pages'] ?? false,
    );
  }
}

class NotificationSummary {
  final int total;
  final int unread;
  final int read;
  final Map<String, int> byType;
  final int recentUnread;

  NotificationSummary({
    required this.total,
    required this.unread,
    required this.read,
    required this.byType,
    required this.recentUnread,
  });

  factory NotificationSummary.fromJson(Map<String, dynamic> json) {
    return NotificationSummary(
      total: json['total'] ?? 0,
      unread: json['unread'] ?? 0,
      read: json['read'] ?? 0,
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      recentUnread: json['recent_unread'] ?? 0,
    );
  }
}

class NotificationResponse {
  final List<NotificationModel> notifications;
  final NotificationPagination pagination;
  final NotificationSummary summary;

  NotificationResponse({
    required this.notifications,
    required this.pagination,
    required this.summary,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return NotificationResponse(
      notifications:
          (data['notifications'] as List<dynamic>?)
              ?.map((item) => NotificationModel.fromJson(item))
              .toList() ??
          [],
      pagination: NotificationPagination.fromJson(data['pagination'] ?? {}),
      summary: NotificationSummary.fromJson(data['summary'] ?? {}),
    );
  }
}

class NotificationCountResponse {
  final int unreadCount;
  final String checkedAt;

  NotificationCountResponse({
    required this.unreadCount,
    required this.checkedAt,
  });

  factory NotificationCountResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    return NotificationCountResponse(
      unreadCount: data['unread_count'] ?? 0,
      checkedAt: data['checked_at'] ?? '',
    );
  }
}
