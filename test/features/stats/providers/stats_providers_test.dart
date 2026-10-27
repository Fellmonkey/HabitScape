import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/providers/stats_providers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  test('statsOverview aggregates the year through the history store', () async {
    final today = DateTime.now().toMidnight;
    final db = createTestDatabase();
    addTearDown(db.close);

    await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Бег'));
    await db.habitLogsDao.upsertLogs([
      makeLogCompanion(
        habitId: 1,
        date: today.subtract(const Duration(days: 3)).unixSeconds,
      ),
      makeLogCompanion(
        habitId: 1,
        date: today.subtract(const Duration(days: 2)).unixSeconds,
      ),
    ]);
    await db.dayNotesDao.upsertNote(
      today.subtract(const Duration(days: 1)).unixSeconds,
      moment: 'Хороший день',
      mood: DayMood.good,
    );

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final overview = await container.read(statsOverviewProvider.future);

    expect(overview.days, isNotEmpty);
    expect(overview.yearTotalDone, greaterThan(0));
    expect(overview.moodCorrelation, isNotNull);
    expect(overview.weekTrend, isNotNull);
    expect(overview.rhythm, isNotNull);
  });

  test('statsOverview is empty on a fresh install', () async {
    final db = createTestDatabase();
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final overview = await container.read(statsOverviewProvider.future);
    expect(overview.yearTotalDone, 0);
    expect(overview.days, isNotEmpty); // the window still spans 365 days
  });
}
