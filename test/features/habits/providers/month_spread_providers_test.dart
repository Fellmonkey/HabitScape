import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/domain/completion.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/providers/month_spread_providers.dart';

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

  Future<List<MonthSpreadDay>> readDays(int monthTs) {
    final completer = Completer<List<MonthSpreadDay>>();
    final sub = container.listen(monthSpreadProvider(monthTs), (_, next) {
      if (next case AsyncData(:final value) when !completer.isCompleted) {
        completer.complete(value);
      }
    }, fireImmediately: true);
    addTearDown(sub.close);
    return completer.future.timeout(const Duration(seconds: 10));
  }

  Future<int> seedDailyHabit() async {
    return db.habitsDao.insertHabit(
      makeHabitCompanion(
        name: 'Зарядка',
        frequencyType: 'daily',
        createdAt: DateTime.utc(2026, 1, 1).unixSeconds,
      ),
    );
  }

  test('monthSpreadProvider builds one day per calendar day', () async {
    final id = await seedDailyHabit();
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: id,
        date: DateTime.utc(2026, 3, 1).unixSeconds,
        status: LogStatus.done,
        loggedHour: 8,
      ),
    );

    final monthTs = DateTime.utc(2026, 3, 1).unixSeconds;
    final days = await readDays(monthTs);

    expect(days, hasLength(31)); // March 2026
    expect(days.every((d) => d.expected == 1), isTrue);
    expect(days.first.done, 1);
    expect(days[1].done, 0);
  });

  test(
    'summary counts only elapsed days — future days never count as missed',
    () async {
      final id = await seedDailyHabit();
      // Done every day of March 1–15 (the pinned today).
      await db.habitLogsDao.upsertLogs([
        for (var day = 1; day <= 15; day++)
          makeLogCompanion(
            habitId: id,
            date: DateTime.utc(2026, 3, day).unixSeconds,
            status: LogStatus.done,
            loggedHour: 8,
          ),
      ]);

      final monthTs = DateTime.utc(2026, 3, 1).unixSeconds;
      await readDays(monthTs);
      final summary = container.read(monthSpreadSummaryProvider(monthTs));

      expect(summary.completionPct, 100.0);
      expect(summary.momentsCount, 0);
      expect(summary.moodCounts.values.reduce((a, b) => a + b), 0);
    },
  );

  test('mood counts come from the day notes', () async {
    await seedDailyHabit();
    await db.dayNotesDao.upsertNote(
      DateTime.utc(2026, 3, 2).unixSeconds,
      moment: 'Хороший день',
      mood: DayMood.good,
    );
    await db.dayNotesDao.upsertNote(
      DateTime.utc(2026, 3, 4).unixSeconds,
      mood: DayMood.bad,
    );

    final monthTs = DateTime.utc(2026, 3, 1).unixSeconds;
    await readDays(monthTs);
    final summary = container.read(monthSpreadSummaryProvider(monthTs));

    expect(summary.moodCounts[DayMood.good], 1);
    expect(summary.moodCounts[DayMood.bad], 1);
    expect(summary.momentsCount, 1); // only the note with a moment
  });

  test(
    'a future month still renders its calendar but has no percentage',
    () async {
      await seedDailyHabit();
      final monthTs = DateTime.utc(2026, 4, 1).unixSeconds;
      final days = await readDays(monthTs);
      final summary = container.read(monthSpreadSummaryProvider(monthTs));

      expect(days, hasLength(30)); // April 2026
      expect(summary.completionPct, isNull);
    },
  );
}
