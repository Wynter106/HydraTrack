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
    // 알림 채널(안드로이드)
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
      matchDateTimeComponents: DateTimeComponents.time, // ❌ 이건 "매일 같은 시간"용이라 MVP에선 빼는 게 안전
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



    /// 매일 3번(기본: 10:00 / 14:00 / 18:00) 물 마시기 알림 스케줄
Future<void> scheduleDailyHydrationReminders({
  List<TimeOfDay>? times,
}) async {
  // 기본값 세팅 (const list literal 문제 회피)
  times ??=  [
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];

  // 채널(안드로이드)
  const androidDetails = AndroidNotificationDetails(
    'hydration_channel',
    'Hydration Reminders',
    channelDescription: 'Reminders to drink water',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  const details = NotificationDetails(android: androidDetails);

  // 기존 알림 먼저 정리(중복 방지)
  await cancelHydrationDailyReminders();

  final now = tz.TZDateTime.now(tz.local);

  for (int i = 0; i < times.length; i++) {
    final t = times[i];

    // 오늘 t시에 해당하는 시간
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      t.hour,
      t.minute,
    );

    // 이미 시간이 지났으면 내일로
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // id를 각각 다르게(1001,1002,1003)
    final id = hydrationReminderId + i;

    await _plugin.zonedSchedule(
      id,
      'HydraTrack',
      'Time to drink water 💧',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시간 반복
    );
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


  /// 매일 3번 알림 취소 (1001~1003)
  Future<void> cancelHydrationDailyReminders() async {
    for (int i = 0; i < 3; i++) {
      await _plugin.cancel(hydrationReminderId + i);
    }
  }


}
