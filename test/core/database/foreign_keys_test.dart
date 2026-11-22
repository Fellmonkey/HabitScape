import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/database/app_database.dart' show AppDatabase;
import 'package:habitscape/domain/enums.dart';

import '../../fixtures/test_factories.dart';

void main() {
  test('production database enforces ON DELETE CASCADE', () async {
    // Deliberately no `setup` callback here: the app's own beforeOpen must
    // enable foreign keys, just like a real device.
    final db = AppDatabase.test(NativeDatabase.memory());
    addTearDown(db.close);

    final habitId = await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Бег'),
    );
    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: 1700086400,
        status: LogStatus.done,
      ),
    );
    expect(await db.habitLogsDao.getAllLogs(), hasLength(1));

    await db.habitsDao.deleteHabit(habitId);
    expect(await db.habitLogsDao.getAllLogs(), isEmpty);
  });
}
