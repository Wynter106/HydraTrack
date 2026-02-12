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
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
  }

  /// 매일 1번: 사용자가 고른 시간(time)에 반복 알림
  Future<void> scheduleDailyHydrationReminder(TimeOfDay time) async {
    // 중복 방지: 기존 스케줄 제거
    await cancelHydrationReminder();

    const androidDetails = AndroidNotificationDetails(
      'hydration_channel',
      'Hydration Reminders',
      channelDescription: 'Reminders to drink water',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);

    // 오늘 time 시각
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 이미 지났으면 내일로
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      hydrationReminderId,
      'HydraTrack',
      'Time to drink water 💧',
      scheduled,
      details,
      // exact 알람 권한 이슈 피하려고 inexact 사용 (더 안정적)
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시간 반복
    );
  }

  Future<void> cancelHydrationReminder() async {
    await _plugin.cancel(hydrationReminderId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// (옵션) 토글 켰을 때 바로 뜨는 “확인용” 알림
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
}
