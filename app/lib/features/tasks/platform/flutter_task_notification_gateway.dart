// flutter_local_notifications-backed [TaskNotificationGateway] (T5.3,
// FR-1.4.2). Schedules via AlarmManager so a reminder fires even with the app
// fully closed. The fire instant is converted to UTC and scheduled with
// `absoluteTime` interpretation, so the device's wall clock fires it at the
// right local moment without needing a timezone-name lookup.
//
// Exact-alarm permission (Android 12+) is requested up front; if the user
// revokes it we fall back to inexact scheduling rather than throwing, so a
// denied permission degrades quietly.

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rivendell/features/tasks/application/task_notification_gateway.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class FlutterTaskNotificationGateway implements TaskNotificationGateway {
  FlutterTaskNotificationGateway();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Android 8+ requires a notification channel for a notification to show.
  // High importance/priority so a due-day reminder is surfaced, not silenced.
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'task_reminders',
      'Task reminders',
      channelDescription: 'Reminders for upcoming review tasks',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  @override
  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
    );
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // POST_NOTIFICATIONS (Android 13+). We do NOT call
    // requestExactAlarmsPermission here: on 12+ that opens the system Settings
    // page if the grant is missing, which is jarring. Exact alarms are granted
    // by default at install for apps that declare SCHEDULE_EXACT_ALARM; if the
    // user later revokes one, [schedule]'s exact→inexact fallback keeps
    // reminders firing (just less precisely).
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required DateTime fireTime,
    String? body,
  }) async {
    final instant = tz.TZDateTime.from(fireTime, tz.UTC);
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: instant,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException {
      // Exact-alarm grant denied (Android 12+). Fall back to inexact so a
      // denied permission degrades gracefully instead of throwing.
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: instant,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
