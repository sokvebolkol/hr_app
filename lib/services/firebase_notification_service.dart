import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class FirebaseNotificationService {
  static final FirebaseNotificationService _instance =
      FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _repository = NotificationRepository();

  bool _isInitialized = false;
  String? _fcmToken;

  // Notification callback
  Function(NotificationModel)? onNotificationReceived;
  Function(NotificationModel)? onNotificationTapped;

  /// Initialize Firebase Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if not already done
      if (!Firebase.apps.isNotEmpty) {
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
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
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
      AndroidNotificationChannel(
        'default_channel',
        'Default Notifications',
        description: 'General notifications',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'leave_channel',
        'Leave Notifications',
        description: 'Leave request and approval notifications',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'attendance_channel',
        'Attendance Notifications',
        description: 'Attendance and clock-in reminders',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      ),
      AndroidNotificationChannel(
        'urgent_channel',
        'Urgent Notifications',
        description: 'Important and urgent notifications',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('urgent'),
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
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

        // Send token to server
        await _sendTokenToServer(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        await _sendTokenToServer(newToken);
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Send FCM token to server
  Future<void> _sendTokenToServer(String token) async {
    try {
      await _repository.updateFCMToken(token);
      print('✅ FCM token sent to server');
    } catch (e) {
      print('❌ Error sending FCM token to server: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Foreground message received: ${message.messageId}');

    final notification = NotificationModel.fromRemoteMessage(message);

    // Save to local storage
    await _repository.saveNotificationLocally(notification);

    // Show local notification
    await _showLocalNotification(notification);

    // Trigger callback
    onNotificationReceived?.call(notification);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.messageId}');

    final notification = NotificationModel.fromRemoteMessage(message);

    // Mark as read
    await _repository.markNotificationAsRead(notification.id);

    // Trigger callback
    onNotificationTapped?.call(notification);
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      final notificationData = jsonDecode(response.payload!);
      final notification = NotificationModel.fromJson(notificationData);

      // Mark as read
      await _repository.markNotificationAsRead(notification.id);

      // Trigger callback
      onNotificationTapped?.call(notification);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    final channelId = _getChannelId(notification.type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance:
          notification.priority == NotificationPriority.high
              ? Importance.high
              : Importance.defaultImportance,
      priority:
          notification.priority == NotificationPriority.high
              ? Priority.high
              : Priority.defaultPriority,
      showWhen: true,
      when: notification.createdAt.millisecondsSinceEpoch,
      icon: '@mipmap/ic_launcher',
      largeIcon:
          notification.imageUrl != null
              ? DrawableResourceAndroidBitmap(notification.imageUrl!)
              : null,
      styleInformation:
          notification.body.length > 50
              ? BigTextStyleInformation(
                notification.body,
                contentTitle: notification.title,
                htmlFormatBigText: true,
                htmlFormatContentTitle: true,
              )
              : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
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
  String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.leave:
        return 'leave_channel';
      case NotificationType.attendance:
        return 'attendance_channel';
      case NotificationType.urgent:
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
    return await _repository.getUnreadNotificationCount();
  }

  /// Update badge count
  Future<void> updateBadgeCount() async {
    final count = await getBadgeCount();
    // You can implement platform-specific badge update here
    print('📛 Badge count: $count');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background message received: ${message.messageId}');

  // Handle background message
  final notification = NotificationModel.fromRemoteMessage(message);
  final repository = NotificationRepository();
  await repository.saveNotificationLocally(notification);
}
