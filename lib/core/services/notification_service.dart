import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/models/health_profile.dart';

/// ─── LOCAL NOTIFICATION & DIRECT UPDATE TRIGGER SERVICE ───────────────────
///
/// Features:
/// 1. Cycle & Period proactive health reminders.
/// 2. One-time legacy user update campaign notifications.
/// 3. Direct tap-to-update payload routing (`kholo_update`).
/// ────────────────────────────────────────────────────────────────────────────
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static ValueChanged<String>? onNotificationTap;

  static const _channelId = 'kholo_cycle';
  static const _channelName = 'Cycle & Health Reminders';
  static const _channelDesc =
      'Period reminders, fertile window alerts, daily log nudges';

  /// Call once from main() before runApp.
  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          onNotificationTap?.call(response.payload!);
        }
      },
    );

    // Proactively register notification channels on Android
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'kholo_updates_channel',
            'KHOLO App Updates',
            description: 'Important updates and new features for KHOLO',
            importance: Importance.max,
            enableVibration: true,
            playSound: true,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            enableVibration: true,
            playSound: true,
          ),
        );
      }
    }

    _initialized = true;
  }

  /// Request notification permission on Android 13+.
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? false;
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Schedule all cycle-based reminders based on [profile].
  /// Cancels existing reminders first, so safe to call on profile update.
  static Future<void> scheduleReminders(HealthProfile profile) async {
    await cancelAll();
    if (profile.lastPeriodDate == null) return;

    final now = DateTime.now();
    final nextPeriod = profile.lastPeriodDate!
        .add(Duration(days: profile.safeCycleLength));

    // ── Notification 1: Period in 2 days ─────────────────────────────────
    final twoBeforePeriod = nextPeriod.subtract(const Duration(days: 2));
    if (twoBeforePeriod.isAfter(now)) {
      await _scheduleAt(
        id: 1001,
        title: '🩸 Period arriving soon',
        body:
            'Your period is expected in about 2 days. Stock up on care essentials!',
        scheduledDate: twoBeforePeriod.copyWith(hour: 9, minute: 0),
      );
    }

    // ── Notification 2: Period day ────────────────────────────────────────
    if (nextPeriod.isAfter(now)) {
      await _scheduleAt(
        id: 1002,
        title: '🩸 Period day estimated',
        body: 'Today may be the start of your period. Log your flow in KHOLO.',
        scheduledDate: nextPeriod.copyWith(hour: 8, minute: 0),
      );
    }

    // ── Notification 3: Fertile window start (~day 11) ───────────────────
    final fertileStart = profile.lastPeriodDate!
        .add(Duration(days: profile.safeCycleLength - 17));
    if (fertileStart.isAfter(now)) {
      await _scheduleAt(
        id: 1003,
        title: '✨ Fertile window beginning',
        body:
            'Your estimated fertile window starts around now. Check your insights!',
        scheduledDate: fertileStart.copyWith(hour: 9, minute: 0),
      );
    }

    // ── Notification 4: Daily log reminder (tomorrow 8 PM) ────────────────
    final tomorrow8pm =
        now.add(const Duration(days: 1)).copyWith(hour: 20, minute: 0);
    await _scheduleAt(
      id: 1004,
      title: '📋 Log today\'s symptoms',
      body:
          'Track your mood, energy, and symptoms to get better cycle insights.',
      scheduledDate: tomorrow8pm,
    );

    debugPrint('[NotificationService] Reminders scheduled ✓');
  }

  static Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static const int updateNotificationId = 9999;

  /// Shows an immediate system status bar notification when a NEW update is found.
  static Future<void> showUpdateNotification({
    required String version,
    required int versionCode,
    String? releaseNotes,
    bool force = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotifiedCode =
          prefs.getInt('kholo_last_notified_version_code') ?? 0;

      // Deduplicate unless forced
      if (!force && versionCode <= lastNotifiedCode) {
        debugPrint(
          '[NotificationService] Already notified for update versionCode: $versionCode. Skipping.',
        );
        return;
      }

      await init();
      await requestPermission();

      const androidDetails = AndroidNotificationDetails(
        'kholo_updates_channel',
        'KHOLO App Updates',
        channelDescription: 'Important updates and new features for KHOLO',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: true,
        playSound: true,
        color: Color(0xFF92003A),
        icon: '@mipmap/launcher_icon',
      );
      const iosDetails =
          DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
      const details =
          NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _plugin.show(
        updateNotificationId,
        '🌸 নতুন KHOLO v$version আপডেট উপলব্ধ!',
        'নতুন আপডেটটি পেতে ট্যাপ করুন • Tap here to update now.',
        details,
        payload: 'kholo_update',
      );

      // Mark this version code as notified so subsequent app opens will NOT spam the user
      await prefs.setInt('kholo_last_notified_version_code', versionCode);
      await prefs.setInt('kholo_last_notified_update_code', versionCode);
    } catch (e) {
      debugPrint('[NotificationService] showUpdateNotification error: $e');
    }
  }

  /// Cancels any active in-app update notification (e.g. after update or dismissal)
  static Future<void> cancelUpdateNotification() async {
    try {
      await _plugin.cancel(updateNotificationId);
    } catch (_) {}
  }

  /// Cancel all scheduled KHOLO notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
