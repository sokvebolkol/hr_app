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
  Function(String action, Map<String, dynamic> data)? onNavigationRequired;

  /// Initialize Firebase Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase if not already done
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      print('🔧 Initializing Firebase Notification Service...');

      // Request permissions first
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Configure FCM
      await _configureFCM();

      // Get FCM token
      await _getFCMToken();

      // Check permissions status
      await _checkPermissionStatus();

      _isInitialized = true;
      print('✅ Firebase Notification Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase Notification Service: $e');
      rethrow;
    }
  }

  /// Request notification permissions with explicit iOS handling
  Future<NotificationSettings> _requestPermissions() async {
    print('📱 Requesting notification permissions...');

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📋 Permission status: ${settings.authorizationStatus}');
    print('📋 Alert setting: ${settings.alert}');
    print('📋 Badge setting: ${settings.badge}');
    print('📋 Sound setting: ${settings.sound}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permissions granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ Provisional notification permissions granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ Notification permissions denied');
    } else {
      print('❓ Notification permissions not determined');
    }

    return settings;
  }

  /// Initialize local notifications with better iOS configuration
  Future<void> _initializeLocalNotifications() async {
    print('🔧 Initializing local notifications...');

    const androidSettings = local_notifications.AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // More explicit iOS settings
    const iosSettings = local_notifications.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // onDidReceiveLocalNotification: null, // For iOS < 10
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initSettings = local_notifications.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final isInitialized = await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    if (isInitialized == true) {
      print('✅ Local notifications initialized successfully');
    } else {
      print('❌ Failed to initialize local notifications');
    }

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // For iOS, request permissions again through local notifications
    if (Platform.isIOS) {
      final iosPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                local_notifications.IOSFlutterLocalNotificationsPlugin
              >();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('📱 iOS local notification permissions: $granted');
      }
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              local_notifications.AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      const channels = [
        local_notifications.AndroidNotificationChannel(
          'default_channel',
          'Default Notifications',
          description: 'General notifications',
          importance: local_notifications.Importance.high,
          enableVibration: true,
          playSound: true,
        ),
        local_notifications.AndroidNotificationChannel(
          'leave_channel',
          'Leave Notifications',
          description: 'Leave request and approval notifications',
          importance: local_notifications.Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      ];

      for (final channel in channels) {
        await androidPlugin.createNotificationChannel(channel);
      }
      print('✅ Android notification channels created');
    }
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureFCM() async {
    print('🔧 Configuring FCM...');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }

    print('✅ FCM configured successfully');
  }

  /// Get and log FCM token
  Future<void> _getFCMToken() async {
    try {
      // For iOS, ensure APNS token is available first
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          print('📱 APNS Token available');
        } else {
          print('⚠️ APNS Token not available - notifications may not work');
          // Wait a bit and try again
          await Future.delayed(const Duration(seconds: 2));
          final retryApnsToken = await _firebaseMessaging.getAPNSToken();
          if (retryApnsToken != null) {
            print('📱 APNS Token available after retry');
          } else {
            print('❌ APNS Token still not available');
          }
        }
      }

      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: $_fcmToken');

        // Save token to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
        print('✅ FCM token saved locally');
      } else {
        print('❌ Failed to get FCM token');
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        _fcmToken = newToken;
        print('🔄 FCM token refreshed: $newToken');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
      });
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Check current permission status
  Future<void> _checkPermissionStatus() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    print('📋 Current notification settings:');
    print('  Authorization Status: ${settings.authorizationStatus}');
    print('  Alert: ${settings.alert}');
    print('  Badge: ${settings.badge}');
    print('  Sound: ${settings.sound}');
    print('  Announcement: ${settings.announcement}');
    print('  Car Play: ${settings.carPlay}');
    print('  Critical Alert: ${settings.criticalAlert}');
    // print('  Provisional: ${settings.provisional}');

    if (Platform.isIOS) {
      final apnsToken = await _firebaseMessaging.getAPNSToken();
      print(
        '  APNS Token: ${apnsToken != null ? 'Available' : 'Not Available'}',
      );
    }
  }

  /// Handle foreground messages - ALWAYS show on iOS
  void _handleForegroundMessage(RemoteMessage message) async {
    print('📨 === FOREGROUND MESSAGE RECEIVED ===');
    print('📨 Message ID: ${message.messageId}');
    print('📨 Title: ${message.notification?.title}');
    print('📨 Body: ${message.notification?.body}');
    print('📨 Data: ${message.data}');
    print('📨 From: ${message.from}');
    // print('📨 To: ${message.to}');
    print('📨 Sent Time: ${message.sentTime}');
    print('📨 TTL: ${message.ttl}');
    print('📨 === END FOREGROUND MESSAGE ===');

    final notification = _createNotificationFromRemoteMessage(message);

    // ALWAYS show local notification on iOS when app is in foreground
    await _showLocalNotification(notification);

    // Trigger callback
    onNotificationReceived?.call(notification);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.messageId}');
    print('👆 Data: ${message.data}');

    final notification = _createNotificationFromRemoteMessage(message);

    // Handle specific navigation based on click_action
    final clickAction = notification.data['click_action'] as String?;
    if (clickAction != null && onNavigationRequired != null) {
      print('🧭 Navigating to: $clickAction');
      onNavigationRequired!(clickAction, notification.data);
    }

    // Trigger callback
    onNotificationTapped?.call(notification);
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(
    local_notifications.NotificationResponse response,
  ) async {
    print('👆 Local notification tapped: ${response.id}');

    if (response.payload != null) {
      try {
        final notificationData = jsonDecode(response.payload!);
        final notification = NotificationModel.fromJson(notificationData);

        // Handle specific navigation based on click_action
        final clickAction = notification.data['click_action'] as String?;
        if (clickAction != null && onNavigationRequired != null) {
          print('🧭 Navigating to: $clickAction');
          onNavigationRequired!(clickAction, notification.data);
        }

        // Trigger callback
        onNotificationTapped?.call(notification);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
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

  /// Show local notification with better iOS configuration
  Future<void> _showLocalNotification(NotificationModel notification) async {
    print('📱 Showing local notification: ${notification.title}');

    final channelId = _getChannelId(notification.type);

    // Android notification details
    final androidDetails = local_notifications.AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: local_notifications.Importance.high,
      priority: local_notifications.Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    // iOS notification details - simplified but effective
    final iosDetails = local_notifications.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
      badgeNumber: await getBadgeCount(),
      threadIdentifier: notification.type,
      categoryIdentifier: 'hr_notification',
      subtitle: _getNotificationSubtitle(notification.type),
    );

    final details = local_notifications.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        details,
        payload: jsonEncode(notification.toJson()),
      );
      print('✅ Local notification shown successfully');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Get notification subtitle for iOS
  String _getNotificationSubtitle(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return 'Leave Management';
      case 'attendance':
        return 'Attendance';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Chokchey HR';
    }
  }

  /// Get appropriate channel ID based on notification type
  String _getChannelId(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return 'leave_channel';
      case 'attendance':
        return 'attendance_channel';
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
      default:
        return 'General notifications';
    }
  }

  /// Test notification (for debugging)
  Future<void> showTestNotification() async {
    print('🧪 Showing test notification...');

    final testNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Test Notification',
      body: 'This is a test notification from Chokchey HR',
      type: 'test',
      category: 'info',
      data: {'test': 'true'},
      isRead: false,
      readAt: null,
      createdAt: DateTime.now().toIso8601String(),
      timeAgo: 'now',
      isRecent: true,
    );

    await _showLocalNotification(testNotification);
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
    print('🧹 All notifications cleared');
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

  /// Check iOS notification permissions
  Future<bool> hasIOSPermissions() async {
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    }
    return true;
  }

  /// Get detailed permission status
  Future<Map<String, dynamic>> getPermissionStatus() async {
    final settings = await _firebaseMessaging.getNotificationSettings();

    return {
      'authorizationStatus': settings.authorizationStatus.toString(),
      'alert': settings.alert.toString(),
      'badge': settings.badge.toString(),
      'sound': settings.sound.toString(),
      'hasAPNSToken':
          Platform.isIOS
              ? (await _firebaseMessaging.getAPNSToken()) != null
              : null,
      'fcmToken': _fcmToken,
    };
  }

  /// Enhanced debugging method to check all notification states
  Future<void> debugNotificationStatus() async {
    print('🐛 === NOTIFICATION DEBUG INFO ===');

    // Check Firebase initialization
    print('🔥 Firebase initialized: ${Firebase.apps.isNotEmpty}');

    // Check FCM token
    final token = await _firebaseMessaging.getToken();
    print('📱 Current FCM Token: $token');

    // Check APNS token (iOS)
    if (Platform.isIOS) {
      final apnsToken = await _firebaseMessaging.getAPNSToken();
      print('🍎 APNS Token: ${apnsToken != null ? 'Available' : 'Missing'}');
    }

    // Check permissions in detail
    final settings = await _firebaseMessaging.getNotificationSettings();
    print('📋 Authorization Status: ${settings.authorizationStatus}');
    print('📋 Alert: ${settings.alert}');
    print('📋 Badge: ${settings.badge}');
    print('📋 Sound: ${settings.sound}');

    // Check local notification permissions
    if (Platform.isIOS) {
      final iosPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
                local_notifications.IOSFlutterLocalNotificationsPlugin
              >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('📱 Local notification permissions: $granted');
      }
    }

    print('🐛 === END DEBUG INFO ===');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background message received: ${message.messageId}');
  print('📨 Title: ${message.notification?.title}');
  print('📨 Body: ${message.notification?.body}');
}
