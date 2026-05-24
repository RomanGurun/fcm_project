import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler — must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM] Background message received: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Notification channel ID for Android
  static const String _channelId = 'fcm_high_importance';
  static const String _channelName = 'FCM Notifications';
  static const String _channelDesc = 'High importance FCM notifications';

  // Shared prefs key
  static const String _historyKey = 'notification_history';

  /// Call once in main() after Firebase.initializeApp()
  Future<void> initialize() async {
    // 1. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permissions (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('[FCM] Permission status: ${settings.authorizationStatus}');

    // 3. Set up local notifications
    await _initLocalNotifications();

    // 4. Fetch & cache device token
    _fcmToken = await _messaging.getToken();
    print('[FCM] Token: $_fcmToken');

    // Refresh token listener
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('[FCM] Token refreshed: $newToken');
    });

    // 5. Foreground messages
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 6. Notification opened app from background
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 7. Check if app was launched from a terminated-state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('[FCM] App launched via notification: ${initialMessage.messageId}');
      await _saveToHistory(initialMessage, source: 'terminated');
    }
  }

  // ── Local Notifications Setup ──────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('[LocalNotif] Tapped: ${details.payload}');
      },
    );

    // Create Android high-importance channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Message Handlers ───────────────────────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    print('[FCM] Foreground message: ${message.messageId}');
    await _saveToHistory(message, source: 'foreground');
    _showLocalNotification(message);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    print('[FCM] Notification opened app: ${message.messageId}');
    _saveToHistory(message, source: 'background');
  }

  // ── Show Local Notification ────────────────────────────────────────────────

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title ?? 'New Notification',
      notification.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Notification History ───────────────────────────────────────────────────

  Future<void> _saveToHistory(
    RemoteMessage message, {
    required String source,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];

    final entry = jsonEncode({
      'id': message.messageId ?? DateTime.now().toIso8601String(),
      'title': message.notification?.title ?? '(no title)',
      'body': message.notification?.body ?? '(no body)',
      'data': message.data,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    });

    history.insert(0, entry); // newest first
    if (history.length > 50) history.removeLast(); // cap at 50

    await prefs.setStringList(_historyKey, history);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    return history.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Subscribe to a topic (e.g. "news", "offers")
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('[FCM] Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('[FCM] Unsubscribed from topic: $topic');
  }
}
