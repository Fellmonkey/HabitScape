import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/database/app_database.dart' show AppDatabase;
import 'package:habitscape/core/database/database_provider.dart';
import 'package:habitscape/core/settings/today.dart';
import 'package:habitscape/core/utils/date_helpers.dart';
import 'package:habitscape/domain/enums.dart';
import 'package:habitscape/features/habits/providers/habit_group_actions.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  final today = DateTime.utc(2026, 1, 1);

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'markAllDone writes done and undoAll restores previous statuses',
    () async {
      final id = await db.habitsDao.insertHabit(
        makeHabitCompanion(name: 'Группа'),
      );
      await db.habitLogsDao.upsertLog(
        makeLogCompanion(
          habitId: id,
          date: today.unixSeconds,
          status: LogStatus.skip,
        ),
      );

      final actions = container.read(habitGroupActionsProvider.notifier);
      // The stream has not emitted yet in this isolated container, so no
      // previous status is captured; undo with an explicit snapshot instead.
      final previous = await actions.markAllDone([id]);
      expect(previous, isEmpty);
      expect(
        (await db.habitLogsDao.getLogsForHabitInRange(
          id,
          today.unixSeconds,
          today.unixSeconds + 1,
        )).single.status,
        LogStatus.done,
      );

      await actions.undoAll([id], {id: LogStatus.skip});
      expect(
        (await db.habitLogsDao.getLogsForHabitInRange(
          id,
          today.unixSeconds,
          today.unixSeconds + 1,
        )).single.status,
        LogStatus.skip,
      );
    },
  );
}
