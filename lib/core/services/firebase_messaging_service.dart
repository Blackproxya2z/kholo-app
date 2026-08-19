import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// ─── FIREBASE CLOUD MESSAGING (FCM) SERVICE ─────────────────────────────────
///
/// Features:
/// 1. Remote push notifications for updates, alerts, and wellness announcements.
/// 2. Background and foreground payload routing:
///    - Category A: Update notifications (kholo_update)
///    - Category B: Important announcements (kholo_announcement)
///    - Category C: User reminders (kholo_reminder)
/// 3. Standard topic subscription (`kholo_updates`, `kholo_announcements`, `kholo_reminders`).
/// 4. Direct integration with KHOLO local notification engine.
/// ────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> kholoFirebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Received message ID: ${message.messageId}');
  final data = message.data;
  final title = message.notification?.title ?? data['title'] ?? 'KHOLO Health Update';
  final body = message.notification?.body ?? data['body'] ?? 'Important announcement from KHOLO';
  final payload = data['payload'] ?? data['action'] ?? 'kholo_update';

  if (payload == 'kholo_update') {
    final version = data['latest_version'] ?? '1.3.0';
    final code = int.tryParse(data['version_code']?.toString() ?? '20') ?? 20;
    await NotificationService.showUpdateNotification(
      version: version,
      versionCode: code,
      releaseNotes: body,
      force: data['force_update'] == 'true',
    );
  } else if (payload == 'kholo_announcement') {
    await NotificationService.showSimpleNotification(
      title: title,
      body: body,
      payload: 'kholo_announcement',
    );
  } else if (payload == 'kholo_reminder') {
    final reminderType = data['reminder_type'] ?? 'general';
    await NotificationService.showSimpleNotification(
      title: title,
      body: body,
      payload: 'kholo_reminder:$reminderType',
    );
  } else {
    await NotificationService.showSimpleNotification(
      title: title,
      body: body,
      payload: payload,
    );
  }
}

class FirebaseMessagingService {
  FirebaseMessagingService._();

  static bool _isAvailable = false;
  static bool get isAvailable => _isAvailable;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  /// Initialize FCM listeners and topic subscriptions
  static Future<void> init() async {
    try {
      if (kIsWeb) return;
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(kholoFirebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('[FCM Foreground] Received: ${message.notification?.title}');
        final data = message.data;
        final title = message.notification?.title ?? data['title'] ?? 'KHOLO Alert';
        final body = message.notification?.body ?? data['body'] ?? '';
        final payload = data['payload'] ?? data['action'] ?? 'kholo_update';

        if (payload == 'kholo_update') {
          final version = data['latest_version'] ?? '1.3.0';
          final code = int.tryParse(data['version_code']?.toString() ?? '20') ?? 20;
          await NotificationService.showUpdateNotification(
            version: version,
            versionCode: code,
            releaseNotes: body,
            force: data['force_update'] == 'true',
          );
        } else if (payload == 'kholo_announcement') {
          await NotificationService.showSimpleNotification(
            title: title,
            body: body,
            payload: 'kholo_announcement',
          );
        } else if (payload == 'kholo_reminder') {
          final reminderType = data['reminder_type'] ?? 'general';
          await NotificationService.showSimpleNotification(
            title: title,
            body: body,
            payload: 'kholo_reminder:$reminderType',
          );
        } else {
          await NotificationService.showSimpleNotification(
            title: title,
            body: body,
            payload: payload,
          );
        }
      });

      // Handle notification opened app event
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM onMessageOpenedApp] Action triggered: ${message.data}');
        final payload = message.data['payload'] ?? message.data['action'] ?? 'kholo_update';
        NotificationService.onNotificationTap?.call(payload);
      });

      // Retrieve FCM Token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('[FCM Token]: $_fcmToken');
      } catch (e) {
        debugPrint('[FCM] Token retrieval skipped: $e');
      }

      // Auto-subscribe to standard broadcast topics
      await subscribeToTopic('kholo_updates');
      await subscribeToTopic('kholo_announcements');
      await subscribeToTopic('kholo_reminders');

      _isAvailable = true;
    } catch (e) {
      debugPrint('[FCM Service] Fallback mode active: $e');
      _isAvailable = false;
    }
  }

  /// Subscribe to a specific FCM topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      if (kIsWeb) return;
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a specific FCM topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (kIsWeb) return;
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] Error unsubscribing from topic $topic: $e');
    }
  }
}
