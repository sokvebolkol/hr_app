import 'package:firebase_messaging/firebase_messaging.dart';

enum NotificationType { general, leave, attendance, approval, urgent, reminder }

enum NotificationPriority { low, normal, high }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final String? actionUrl;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
    this.imageUrl,
    this.actionUrl,
  });

  factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: _parseNotificationType(message.data['type']),
      priority: _parseNotificationPriority(message.data['priority']),
      createdAt: DateTime.now(),
      data: message.data,
      imageUrl:
          message.notification?.android?.imageUrl ??
          message.notification?.apple?.imageUrl,
      actionUrl: message.data['action_url'],
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: _parseNotificationType(json['type']),
      priority: _parseNotificationPriority(json['priority']),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['is_read'] ?? false,
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      imageUrl: json['image_url'],
      actionUrl: json['action_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'data': data,
      'image_url': imageUrl,
      'action_url': actionUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
    String? imageUrl,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type?.toLowerCase()) {
      case 'leave':
        return NotificationType.leave;
      case 'attendance':
        return NotificationType.attendance;
      case 'approval':
        return NotificationType.approval;
      case 'urgent':
        return NotificationType.urgent;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.general;
    }
  }

  static NotificationPriority _parseNotificationPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.normal;
    }
  }

  String get typeText {
    switch (type) {
      case NotificationType.leave:
        return 'Leave';
      case NotificationType.attendance:
        return 'Attendance';
      case NotificationType.approval:
        return 'Approval';
      case NotificationType.urgent:
        return 'Urgent';
      case NotificationType.reminder:
        return 'Reminder';
      default:
        return 'General';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
