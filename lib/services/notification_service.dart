// lib/services/notification_service.dart
// Handles all local push notifications using flutter_local_notifications.
// Uses the device's DEFAULT system sound + vibration — no custom audio asset needed.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzData;
import '../utils/constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── Messages rotated daily to keep things fresh ──────────────────────────────
  static const _dailyMessages = [
    ('🐔 The farmer is waiting…', 'Your high score won\'t beat itself! Come run!'),
    ('💨 Time to CLUCK & RUN!',   'The farmer sharpened his pitchfork. Can you escape?'),
    ('🏆 Daily challenge ready!', 'Can you beat ${kAppName} today? Open and find out!'),
    ('🌾 The farm is restless…',  'New obstacles. Faster farmer. Same hungry ending?'),
    ('🐔 Bock bock bock!',        'Your chicken misses you. Jump back in!'),
    ('⚡ Speed run alert!',        'The farmer is angrier than ever. Prove you\'re faster!'),
    ('🎯 Beat your record!',      'Yesterday\'s score needs some company. Come challenge it!'),
  ];

  // ── Init ──────────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    tzData.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // ── Permission request (call after onboarding) ───────────────────────────────
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      bool granted = false;
      if (android != null) {
        granted = await android.requestNotificationsPermission() ?? false;
        await android.requestExactAlarmsPermission();
      }
      if (ios != null) {
        granted = await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
            false;
      }
      return granted;
    } catch (e) {
      debugPrint('[Notifications] Permission error: $e');
      return false;
    }
  }

  // ── Schedule daily reminder at 7:00 PM local time ────────────────────────────
  static Future<void> scheduleDailyReminder({int hour = 19, int minute = 0}) async {
    await _plugin.cancel(kNotifDailyId); // cancel existing before rescheduling

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Pick today's message by day-of-year
    final msgIdx = now.dayOfYear % _dailyMessages.length;
    final (title, body) = _dailyMessages[msgIdx];

    await _plugin.zonedSchedule(
      kNotifDailyId,
      title,
      body,
      scheduled,
      _buildDetails(channelId: kNotifChannelId, channelName: kNotifChannelName),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
    debugPrint('[Notifications] Daily reminder scheduled at $hour:$minute');
  }

  // ── New high-score streak notification ───────────────────────────────────────
  static Future<void> showStreakNotification(int streak) async {
    await _plugin.show(
      kNotifStreakId,
      '🔥 $streak-Day Streak!',
      'You\'ve played $streak days in a row. Don\'t break the chain!',
      _buildDetails(channelId: kNotifChannelId, channelName: kNotifChannelName),
    );
  }

  // ── Cancel all ───────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Private helpers ───────────────────────────────────────────────────────────
  static NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: kNotifChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        // Uses device DEFAULT sound and vibration — no custom asset needed
        playSound: true,
        enableVibration: true,
        styleInformation: const BigTextStyleInformation(''),
        icon: '@mipmap/ic_launcher',
        color: kColBlaze,
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        channelShowBadge: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true, // uses default iOS system sound
        interruptionLevel: InterruptionLevel.active,
      ),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    // App is opened from notification — game will handle routing on start
    debugPrint('[Notifications] Tapped: ${response.id}');
  }
}

// Extension for day-of-year
extension _DayOfYear on DateTime {
  int get dayOfYear {
    final start = DateTime(year, 1, 1);
    return difference(start).inDays;
  }
}
