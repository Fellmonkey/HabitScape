import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/notifications/reminder_scheduler.dart'
    show ReminderScheduler;
import 'package:habitscape/features/reminders/domain/reminder_spec.dart';
import 'package:habitscape/features/reminders/providers/reminder_scheduler_provider.dart';
import 'package:habitscape/features/reminders/providers/reminder_sync_provider.dart';

class FakeScheduler implements ReminderScheduler {
  bool granted = true;
  bool failNextSchedule = false;
  Completer<void>? scheduleGate;
  final scheduled = <int, String>{};
  final cancelled = <int>[];
  int cancelAllCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => granted;

  @override
  Future<bool> permissionGranted() async => granted;

  @override
  Future<void> scheduleDaily(ReminderSpec spec) async {
    await scheduleGate?.future;
    if (failNextSchedule) {
      failNextSchedule = false;
      throw StateError('schedule failed');
    }
    scheduled[spec.id] = spec.signature;
  }

  @override
  Future<void> scheduleOneShot(ReminderSpec spec) async {
    await scheduleGate?.future;
    if (failNextSchedule) {
      failNextSchedule = false;
      throw StateError('schedule failed');
    }
    scheduled[spec.id] = spec.signature;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  void setNotificationTapHandler(void Function(String? payload) handler) {}
}

ReminderSpec spec(int id) => ReminderSpec(
  id: id,
  title: 't',
  body: 'b',
  hour: 9,
  minute: 0,
  kind: ReminderKind.habit,
);

void main() {
  late FakeScheduler scheduler;
  late ProviderContainer container;
  late ReminderSync sync;

  setUp(() {
    scheduler = FakeScheduler();
    container = ProviderContainer(
      overrides: [reminderSchedulerProvider.overrideWithValue(scheduler)],
    );
    sync = container.read(reminderSyncProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('signature covers specs, enabled flag and permission', () async {
    await sync.sync([spec(1)], true);
    expect(scheduler.scheduled, {1: spec(1).signature});

    await sync.sync([spec(1)], true);
    expect(scheduler.cancelAllCalls, 0, reason: 'unchanged inputs are a no-op');

    scheduler.granted = false;
    await sync.sync([spec(1)], true);
    expect(scheduler.cancelAllCalls, 1, reason: 'permission change reconciles');

    scheduler.granted = true;
    await sync.sync([spec(1)], false);
    expect(scheduler.cancelAllCalls, 2, reason: 'disabled reconciles');
  });

  test('failed apply keeps the signature so the next call retries', () async {
    // The provider reports this deliberate failure through debugPrint;
    // silence it so the expected error does not pollute the test output.
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {};

    try {
      scheduler.failNextSchedule = true;
      await sync.sync([spec(1)], true);
      expect(container.read(reminderSyncProvider).error, isA<StateError>());
      expect(container.read(reminderSyncProvider).signature, isNull);

      await sync.sync([spec(1)], true);
      expect(container.read(reminderSyncProvider).error, isNull);
      expect(container.read(reminderSyncProvider).signature, isNotNull);
      expect(scheduler.scheduled, {1: spec(1).signature});
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  test('rapid sync calls are serialized', () async {
    final gate = Completer<void>();
    scheduler.scheduleGate = gate;

    final first = sync.sync([spec(1)], true);
    final second = sync.sync([spec(2)], true);
    var secondDone = false;
    unawaited(second.then((_) => secondDone = true));
    await Future<void>.delayed(Duration.zero);

    expect(secondDone, isFalse, reason: 'second call waits for the first');

    gate.complete();
    await Future.wait([first, second]);
    expect(scheduler.scheduled, {2: spec(2).signature});
  });
}
