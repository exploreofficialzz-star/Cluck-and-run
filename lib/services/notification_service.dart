// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzData;
import '../utils/constants.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _messages = [
    ('🐔 The farmer is waiting…',   'Your high score won\'t beat itself. Come run!'),
    ('💨 Time to CLUCK & RUN!',      'The farmer sharpened his pitchfork. Can you escape?'),
    ('🏆 Daily challenge ready!',    'New day, new record. Open and beat your best!'),
    ('🌾 The farm is restless…',     'New obstacles. Faster farmer. Think you can handle it?'),
    ('🐔 Bock bock bock!',           'Your chicken misses you. Jump back in!'),
    ('⚡ Speed run alert!',           'The farmer is angrier than ever. Prove you\'re faster!'),
    ('🎯 Beat your record today!',   'Yesterday\'s score needs some company. Come challenge it!'),
  ];

  static Future<void> init() async {
    tzData.initializeTimeZones();
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ios     = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
        await android.requestExactAlarmsPermission();
      }
      if (ios != null) return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      return true;
    } catch (e) { debugPrint('[Notif] $e'); return false; }
  }

  static Future<void> scheduleDailyReminder({int hour = 19, int minute = 0}) async {
    await _plugin.cancel(kNotifDailyId);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    final idx = now.difference(DateTime(now.year, 1, 1)).inDays % _messages.length;
    final (title, body) = _messages[idx];
    await _plugin.zonedSchedule(
      kNotifDailyId, title, body, scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(kNotifChannelId, kNotifChannelName,
            channelDescription: kNotifChannelDesc,
            importance: Importance.high, priority: Priority.high,
            playSound: true, enableVibration: true,
            icon: '@mipmap/ic_launcher', color: kColBlaze,
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher')),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showStreakNotification(int streak) async {
    await _plugin.show(kNotifStreakId, '🔥 ${streak}-Day Streak!',
        'You\'ve played $streak days in a row. Don\'t break the chain!',
        const NotificationDetails(
          android: AndroidNotificationDetails('cluck_run_reminders', 'Daily Run Reminders',
              importance: Importance.defaultImportance),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ));
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
