import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';

/// Top-level handler for background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Local notifications plugin handles display automatically for data messages.
  // No extra work needed here — the notification is already shown by the OS.
}

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Global navigator key — set this from your MaterialApp
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String _channelId = 'civicsight_notifications';
  static const String _channelName = 'CivicSight Notifications';
  static const String _channelDesc = 'Notifications for new assignments and messages';

  /// Initialize FCM and local notifications. Call once at app startup.
  Future<void> initialize() async {
    // 1. Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Set up local notifications (Android)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 3. Create Android notification channel
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

    // 4. Foreground message handler — show local notification
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // 5. Handle tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 6. Check if app was opened from a terminated-state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Small delay to let navigator attach
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleMessageTap(initialMessage);
      });
    }
  }

  /// Get the current FCM token.
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Save the FCM token to the users table in Supabase.
  Future<void> saveTokenForUser(String uid) async {
    final token = await getToken();
    if (token == null) return;

    await SupabaseService().updateUser(uid, {'fcm_token': token});

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      SupabaseService().updateUser(uid, {'fcm_token': newToken});
    });
  }

  /// Show a local notification when app is in the foreground.
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Handle tap on a notification (from background state).
  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    _navigateFromPayload(data);
  }

  /// Handle tap on a local notification (from foreground state).
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromPayload(data);
    } catch (_) {}
  }

  /// Route to the correct screen based on notification payload.
  void _navigateFromPayload(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'] as String? ?? '';
    final reportId = data['report_id'] as String? ?? '';

    if (reportId.isEmpty) return;

    switch (type) {
      case 'new_assignment':
      case 'new_comment':
        navigator.pushNamed('/task-detail', arguments: reportId);
        break;
      default:
        navigator.pushNamed('/task-detail', arguments: reportId);
    }
  }
}
