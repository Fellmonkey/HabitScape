import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/core/database/app_database.dart' show AppDatabase;
import 'package:habitscape/domain/enums.dart';

import '../../fixtures/test_db.dart';
import '../../fixtures/test_factories.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  test('hasAnySkip checks existence without loading the archive', () async {
    expect(await db.habitLogsDao.hasAnySkip(), isFalse);

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
    expect(await db.habitLogsDao.hasAnySkip(), isFalse);

    await db.habitLogsDao.upsertLog(
      makeLogCompanion(
        habitId: habitId,
        date: 1700172800,
        status: LogStatus.skip,
      ),
    );
    expect(await db.habitLogsDao.hasAnySkip(), isTrue);
  });
}
