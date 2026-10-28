import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/domain/reminder_spec.dart';

/// Seam over the OS notification scheduling. Feature code schedules through
/// this interface, so tests and web builds can substitute a fake/no-op.
abstract interface class ReminderScheduler {
  /// Platform setup; safe to call repeatedly.
  Future<void> initialize();

  /// Asks for permission (Android 13+). Returns whether notifications are
  /// allowed after the request.
  Future<bool> requestPermission();

  /// Whether notifications are currently allowed by the OS.
  Future<bool> permissionGranted();

  /// Schedules a repeating daily reminder at the spec's time.
  Future<void> scheduleDaily(ReminderSpec spec);

  /// Schedules a one-shot reminder at the spec's [ReminderSpec.date].
  Future<void> scheduleOneShot(ReminderSpec spec);

  Future<void> cancel(int id);

  Future<void> cancelAll();

  /// Registers the callback invoked when the user taps a notification; the
  /// payload string is passed through.
  void setNotificationTapHandler(void Function(String? payload) handler);
}

/// Production implementation backed by `flutter_local_notifications`.
class LocalNotificationsReminderScheduler implements ReminderScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function(String?)? _tapHandler;

  static const _channelHabits = 'habits';
  static const _channelSummaries = 'summaries';
  static const _channelReflection = 'reflection';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await _ensureTimeZone();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _tapHandler?.call(response.payload);
      },
    );
    _initialized = true;
  }

  Future<void> _ensureTimeZone() async {
    try {
      tz_data.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Keep the default location; scheduling still works, just in UTC.
    }
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  @override
  Future<bool> permissionGranted() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return (await android?.areNotificationsEnabled()) ?? true;
  }

  /// Channel by id range: habits (1000–4999), reflection nudges (5000+,
  /// 7000+), summaries (6000–6999).
  String _channelFor(int id) {
    if (id >= 1000 && id < 5000) return _channelHabits;
    if (id >= 6000 && id < 7000) return _channelSummaries;
    return _channelReflection;
  }

  NotificationDetails _detailsFor(ReminderSpec spec) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelFor(spec.id),
        switch (_channelFor(spec.id)) {
          _channelHabits => 'Привычки',
          _channelSummaries => 'Итоги',
          _ => 'Рефлексия',
        },
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
  }

  /// The next local occurrence of [hour]:[minute] (today if still ahead,
  /// otherwise tomorrow).
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  @override
  Future<void> scheduleDaily(ReminderSpec spec) async {
    await initialize();
    await _plugin.zonedSchedule(
      spec.id,
      spec.title,
      spec.body,
      _nextInstanceOf(spec.hour, spec.minute),
      _detailsFor(spec),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: spec.payload,
    );
  }

  @override
  Future<void> scheduleOneShot(ReminderSpec spec) async {
    await initialize();
    final date = spec.date!;
    final scheduled = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      spec.hour,
      spec.minute,
    );
    await _plugin.zonedSchedule(
      spec.id,
      spec.title,
      spec.body,
      scheduled,
      _detailsFor(spec),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: spec.payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  @override
  void setNotificationTapHandler(void Function(String? payload) handler) {
    _tapHandler = handler;
  }
}

/// Web-safe no-op: `flutter_local_notifications` has no web implementation,
/// so the PWA silently falls back to in-app nudges (banners, echo, hints).
class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> permissionGranted() async => true;

  @override
  Future<void> scheduleDaily(ReminderSpec spec) async {}

  @override
  Future<void> scheduleOneShot(ReminderSpec spec) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  void setNotificationTapHandler(void Function(String? payload) handler) {}
}

/// The scheduler for the current platform.
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  return kIsWeb
      ? const NoopReminderScheduler()
      : LocalNotificationsReminderScheduler();
});
