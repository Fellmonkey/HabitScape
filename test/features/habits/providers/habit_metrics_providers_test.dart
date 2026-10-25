import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/providers/habit_metrics_providers.dart';
import 'package:rythm/features/habits/providers/habit_streams.dart';
import 'package:rythm/features/habits/domain/habit_engine.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final pinned = DateTime.utc(2026, 3, 15);

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => FixedToday(pinned.unixSeconds)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<HabitLog>> readMonthLogs(
    ({int habitId, int year, int month}) params,
  ) {
    final completer = Completer<List<HabitLog>>();
    final sub = container.listen(habitMonthLogsProvider(params), (_, next) {
      if (next case AsyncData(:final value) when !completer.isCompleted) {
        completer.complete(value);
      }
    }, fireImmediately: true);
    addTearDown(sub.close);
    return completer.future.timeout(const Duration(seconds: 10));
  }

  Future<HabitMetrics> readMetrics(
    ({int habitId, int year, int month}) params,
  ) {
    final completer = Completer<HabitMetrics>();
    final sub = container.listen(habitMetricsProvider(params), (_, next) {
      if (next case AsyncData(:final value) when !completer.isCompleted) {
        completer.complete(value);
      }
    }, fireImmediately: true);
    addTearDown(sub.close);
    return completer.future.timeout(const Duration(seconds: 10));
  }

  /// Waits for a stream provider's first data emission (drift watch streams
  /// emit asynchronously; the plain [dayProgressProvider] reads their cached
  /// value, so it must be settled first).
  Future<void> settleHabits() {
    final completer = Completer<void>();
    final sub = container.listen(activeHabitsProvider, (_, next) {
      if (next case AsyncData() when !completer.isCompleted) {
        completer.complete();
      }
    }, fireImmediately: true);
    addTearDown(sub.close);
    return completer.future.timeout(const Duration(seconds: 10));
  }

  Future<void> settleLogs() {
    final completer = Completer<void>();
    final sub = container.listen(todayLogsProvider, (_, next) {
      if (next case AsyncData() when !completer.isCompleted) {
        completer.complete();
      }
    }, fireImmediately: true);
    addTearDown(sub.close);
    return completer.future.timeout(const Duration(seconds: 10));
  }

  Future<int> seedHabit() async {
    return db.habitsDao.insertHabit(
      makeHabitCompanion(
        name: 'Чтение',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2026, 1, 1).unixSeconds,
      ),
    );
  }

  Future<void> seedDoneLogs(
    int habitId, {
    required DateTime start,
    required int days,
  }) async {
    await db.habitLogsDao.upsertLogs([
      for (var i = 0; i < days; i++)
        makeLogCompanion(
          habitId: habitId,
          date: start.add(Duration(days: i)).unixSeconds,
          status: LogStatus.done,
          loggedHour: 9,
        ),
    ]);
  }

  group('dayProgressProvider', () {
    test('is 0 when nothing is done today', () async {
      await seedHabit();
      await settleHabits();
      await settleLogs();
      expect(container.read(dayProgressProvider), 0.0);
    });

    test('is 1 once every expected habit is done today', () async {
      final id = await seedHabit();
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(
          habitId: id,
          date: pinned.unixSeconds,
          status: LogStatus.done,
          loggedHour: 9,
        ),
      );
      await settleHabits();
      await settleLogs();
      expect(container.read(dayProgressProvider), 1.0);
    });
  });

  group('habitMonthLogsProvider + habitMetricsProvider', () {
    test('metrics match the engine over the pinned month', () async {
      final id = await seedHabit();
      // 10 done logs in February (habit created in January, so fully expected).
      await seedDoneLogs(id, start: DateTime.utc(2026, 2, 1), days: 10);

      final params = (habitId: id, year: 2026, month: 2);
      final logs = await readMonthLogs(params);
      expect(logs, hasLength(10));

      final metrics = await readMetrics(params);
      expect(metrics.absoluteCompletions, 10);
      expect(metrics.requiredBase, 28); // February 2026 has 28 days
      expect(metrics.skipCount, 0);
      expect(metrics.completionPct, closeTo(10 / 28 * 100, 0.001));
      // All logged hours are 9 → morning bucket only.
      expect(metrics.morningRatio, 1.0);
      expect(metrics.afternoonRatio, 0.0);
      expect(metrics.eveningRatio, 0.0);
      expect(metrics.nightRatio, 0.0);
    });

    test('a habit created mid-month halves its required base', () async {
      final id = await db.habitsDao.insertHabit(
        makeHabitCompanion(
          name: 'Поздняя',
          frequencyType: 'daily',
          createdAt: DateTime.utc(2026, 2, 15).unixSeconds,
        ),
      );
      await seedDoneLogs(id, start: DateTime.utc(2026, 2, 15), days: 5);

      final params = (habitId: id, year: 2026, month: 2);
      final metrics = await readMetrics(params);
      expect(metrics.requiredBase, 14); // Feb 15–28
      expect(metrics.absoluteCompletions, 5);
    });
  });
}
