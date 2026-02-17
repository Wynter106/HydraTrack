import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:flutter/material.dart';

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int hydrationReminderId = 1001;

  Future<void> init() async {
    // timezone init (for scheduled notifications)
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);
  }

  Future<void> requestPermissionIfNeeded() async {
    // Android 13+ permission
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
  }

  Future<void> scheduleHydrationReminderEvery2Hours() async {
    const androidDetails = AndroidNotificationDetails(
      'hydration_channel',
      'Hydration Reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const details = NotificationDetails(android: androidDetails);

    // 다음 2시간 후부터 2시간 간격 반복
    final firstTime = tz.TZDateTime.now(tz.local).add(const Duration(hours: 2));

    await _plugin.zonedSchedule(
      hydrationReminderId,
      'HydraTrack',
      'Time to drink water 💧',
      firstTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'For testing notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      9999,
      'Test',
      'Notification is working ✅',
      details,
    );
  }

  Future<void> cancelHydrationReminders() async {
    await _plugin.cancel(hydrationReminderId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }



Future<void> scheduleDailyHydrationReminders({
  List<TimeOfDay>? times,
}) async {
  times ??= [
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 19, minute: 0),
  ];

  const androidDetails = AndroidNotificationDetails(
    'hydration_channel',
    'Hydration Reminders',
    channelDescription: 'Reminders to drink water',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  const details = NotificationDetails(android: androidDetails);

  await cancelHydrationDailyReminders(count: times.length);

  final now = tz.TZDateTime.now(tz.local);

  for (int i = 0; i < times.length; i++) {
    final t = times[i];

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      t.hour,
      t.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final id = hydrationReminderId + i;

    await _plugin.zonedSchedule(
      id,
      'HydraTrack',
      'Time to drink water 💧',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

Future<void> cancelHydrationDailyReminders({int count = 3}) async {
  for (int i = 0; i < count; i++) {
    await _plugin.cancel(hydrationReminderId + i);
  }
}


Future<void> scheduleOneShotTestInSeconds(int seconds) async {
  const androidDetails = AndroidNotificationDetails(
    'test_channel',
    'Test Notifications',
    channelDescription: 'For testing notifications',
    importance: Importance.max,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);

  final scheduled = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
  print('One-shot scheduled at: $scheduled (tz.local=${tz.local.name})');

  await _plugin.zonedSchedule(
    8888,
    'HydraTrack',
    'One-shot in $seconds seconds ✅',
    scheduled,
    details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
Future<void> scheduleTestRemindersNext1to3Minutes() async {
  final now = DateTime.now();

  int addMinutes(int m) => (now.minute + m) % 60;
  int addHoursIfNeeded(int m) =>
      (now.minute + m >= 60) ? ((now.hour + 1) % 24) : now.hour;

  await scheduleDailyHydrationReminders(
    times: [
      TimeOfDay(hour: addHoursIfNeeded(1), minute: addMinutes(1)),
      TimeOfDay(hour: addHoursIfNeeded(2), minute: addMinutes(2)),
      TimeOfDay(hour: addHoursIfNeeded(3), minute: addMinutes(3)),
    ],
  );
}

}
