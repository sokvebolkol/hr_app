import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as local_notifications;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final local_notifications.FlutterLocalNotificationsPlugin
  _localNotifications = local_notifications.FlutterLocalNotificationsPlugin();
  final NotificationRepository _repository = NotificationRepository();

  bool _isInitialized = false;
  String? _fcmToken;

  // Notification callback
  Function(NotificationModel)? onNotificationReceived;
  Function(NotificationModel)? onNotificationTapped;

  // Navigation callback for specific actions
  Function(String action, Map<String, dynamic> data)? onNavigationRequired;

  /// Initialize Firebase Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if not already done
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure FCM
      await _configureFCM();

      // Get FCM token
      await _getFCMToken();

      _isInitialized = true;
      print('✅ Firebase Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase Notification Service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permissions granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ Provisional notification permissions granted');
    } else {
      print('❌ Notification permissions denied');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = local_notifications.AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = local_notifications.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = local_notifications.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const channels = [
      local_notifications.AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'General notifications',
        importance: local_notifications.Importance.high,
      ),
      local_notifications.AndroidNotificationChannel(
        'leave_channel',
        'Leave Notifications',
        description: 'Leave request and approval notifications',
        importance: local_notifications.Importance.high,
      ),
      local_notifications.AndroidNotificationChannel(
        'attendance_channel',
        'Attendance Notifications',
        description: 'Attendance and clock-in reminders',
        importance: local_notifications.Importance.high,
      ),
      local_notifications.AndroidNotificationChannel(
        'urgent_channel',
        'Urgent Notifications',
        description: 'Important and urgent notifications',
        importance: local_notifications.Importance.max,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            local_notifications.AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureFCM() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Save token to preferences
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        print('✅ FCM token saved locally');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        print('🔄 FCM token refreshed: $newToken');
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message received: ${message.messageId}');

    final notification = _createNotificationFromRemoteMessage(message);

    // Show local notification
    await _showLocalNotification(notification);

    // Trigger callback
    onNotificationReceived?.call(notification);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.messageId}');

    final notification = _createNotificationFromRemoteMessage(message);

    // Handle specific navigation based on click_action
    final clickAction = notification.data['click_action'] as String?;
    if (clickAction != null && onNavigationRequired != null) {
      onNavigationRequired!(clickAction, notification.data);
    }

    // Trigger callback
    onNotificationTapped?.call(notification);
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(
    local_notifications.NotificationResponse response,
  ) async {
    if (response.payload != null) {
      try {
        final notificationData = jsonDecode(response.payload!);
        final notification = NotificationModel.fromJson(notificationData);

        // Handle specific navigation based on click_action
        final clickAction = notification.data['click_action'] as String?;
        if (clickAction != null && onNavigationRequired != null) {
          onNavigationRequired!(clickAction, notification.data);
        }

        // Trigger callback
        onNotificationTapped?.call(notification);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Create NotificationModel from RemoteMessage
  NotificationModel _createNotificationFromRemoteMessage(
    RemoteMessage message,
  ) {
    return NotificationModel(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      category: message.data['category'] ?? 'info',
      data: message.data,
      isRead: false,
      readAt: null,
      createdAt: DateTime.now().toIso8601String(),
      timeAgo: 'just now',
      isRecent: true,
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    final channelId = _getChannelId(notification.type);

    final androidDetails = local_notifications.AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance:
          notification.type == 'urgent'
              ? local_notifications.Importance.max
              : local_notifications.Importance.high,
      priority:
          notification.type == 'urgent'
              ? local_notifications.Priority.max
              : local_notifications.Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation:
          notification.body.length > 50
              ? local_notifications.BigTextStyleInformation(
                notification.body,
                contentTitle: notification.title,
              )
              : null,
    );

    const iosDetails = local_notifications.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = local_notifications.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.toJson()),
    );
  }

  /// Get appropriate channel ID based on notification type
  String _getChannelId(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return 'leave_channel';
      case 'attendance':
        return 'attendance_channel';
      case 'urgent':
        return 'urgent_channel';
      default:
        return 'default_channel';
    }
  }

  /// Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'leave_channel':
        return 'Leave Notifications';
      case 'attendance_channel':
        return 'Attendance Notifications';
      case 'urgent_channel':
        return 'Urgent Notifications';
      default:
        return 'Default Notifications';
    }
  }

  /// Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'leave_channel':
        return 'Leave request and approval notifications';
      case 'attendance_channel':
        return 'Attendance and clock-in reminders';
      case 'urgent_channel':
        return 'Important and urgent notifications';
      default:
        return 'General notifications';
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get badge count
  Future<int> getBadgeCount() async {
    try {
      final response = await _repository.getUnreadCount();
      return response.unreadCount;
    } catch (e) {
      print('❌ Error getting badge count: $e');
      return 0;
    }
  }

  /// Update badge count
  Future<void> updateBadgeCount() async {
    final count = await getBadgeCount();
    print('📛 Badge count: $count');

    // For iOS, you can set the badge count
    if (Platform.isIOS) {
      await _firebaseMessaging.setAutoInitEnabled(true);
    }
  }

  /// Subscribe to user-specific topics based on role
  Future<void> subscribeToUserTopics({
    required String userId,
    bool isApprover = false,
    bool isCeo = false,
  }) async {
    try {
      // Subscribe to user-specific topic
      await subscribeToTopic('user_$userId');

      // Subscribe to role-based topics
      if (isApprover) {
        await subscribeToTopic('approvers');
      }

      if (isCeo) {
        await subscribeToTopic('ceo');
      }

      // Subscribe to general HR topics
      await subscribeToTopic('hr_general');

      print('✅ Subscribed to user topics for: $userId');
    } catch (e) {
      print('❌ Error subscribing to user topics: $e');
    }
  }

  /// Unsubscribe from all topics (for logout)
  Future<void> unsubscribeFromAllTopics({
    required String userId,
    bool isApprover = false,
    bool isCeo = false,
  }) async {
    try {
      await unsubscribeFromTopic('user_$userId');

      if (isApprover) {
        await unsubscribeFromTopic('approvers');
      }

      if (isCeo) {
        await unsubscribeFromTopic('ceo');
      }

      await unsubscribeFromTopic('hr_general');

      print('✅ Unsubscribed from all topics for: $userId');
    } catch (e) {
      print('❌ Error unsubscribing from topics: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background message received: ${message.messageId}');

  // You can handle background messages here
  // For example, save to local storage, update badge count, etc.
}
