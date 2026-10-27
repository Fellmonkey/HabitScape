import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/providers/year_summary_providers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  final today = DateTime.utc(2026, 10, 28);

  test('year summary aggregates the trailing year through the store', () async {
    final createdAt = today.subtract(const Duration(days: 400)).unixSeconds;
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Бег', createdAt: createdAt),
    );
    await db.habitLogsDao.upsertLogs([
      for (var day = 1; day <= 10; day++)
        makeLogCompanion(
          habitId: 1,
          date: DateTime.utc(2026, 10, day).unixSeconds,
        ),
    ]);
    await db.dayNotesDao.upsertNote(
      DateTime.utc(2026, 10, 1).unixSeconds,
      moment: 'Момент',
      mood: DayMood.good,
    );
    await db.monthlyGoalsDao.addGoal(today.toMidnight.unixSeconds, 'Цель года');

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
      ],
    );
    addTearDown(container.dispose);

    final year = await container.read(yearSummaryProvider.future);
    expect(year.hasData, isTrue);
    expect(
      year.windowStart,
      today.subtract(const Duration(days: 364)).toMidnight,
    );
    expect(year.today, today.toMidnight);
    expect(year.momentsCount, 1);
    expect(year.moodByDay[DateTime.utc(2026, 10, 1)], DayMood.good);
    expect(year.bestHabit!.name, 'Бег');
    expect(year.goals, (done: 0, total: 1));
  });

  test('quiet year has nothing to show', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
      ],
    );
    addTearDown(container.dispose);

    final year = await container.read(yearSummaryProvider.future);
    expect(year.hasData, isFalse);
  });
}
