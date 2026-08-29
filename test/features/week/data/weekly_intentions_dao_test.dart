import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../../fixtures/test_db.dart';

void main() {
  late AppDatabase db;

  final week1 = DateTime.utc(2026, 10, 26).unixSeconds;
  final week2 = DateTime.utc(2026, 11, 2).unixSeconds;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('WeeklyIntentionsDao', () {
    test('watchForWeek returns null when missing', () async {
      expect(await db.weeklyIntentionsDao.getForWeek(week1), isNull);
    });

    test('setIntention upserts, clears with null/empty', () async {
      await db.weeklyIntentionsDao.setIntention(week1, '  Бег по вторникам  ');
      final intention = await db.weeklyIntentionsDao.getForWeek(week1);
      expect(intention, isNotNull);
      expect(intention!.weekStart, week1);
      expect(intention.intention, 'Бег по вторникам');

      // Upsert same week — one row.
      await db.weeklyIntentionsDao.setIntention(week1, 'Новое намерение');
      final all = await db.weeklyIntentionsDao.getAllIntentions();
      expect(all, hasLength(1));
      expect(all.single.intention, 'Новое намерение');

      // Clear with null.
      await db.weeklyIntentionsDao.setIntention(week1, null);
      expect(
        (await db.weeklyIntentionsDao.getForWeek(week1))!.intention,
        isNull,
      );
    });

    test('deleteAllIntentions clears everything', () async {
      await db.weeklyIntentionsDao.setIntention(week1, 'A');
      await db.weeklyIntentionsDao.setIntention(week2, 'B');
      expect(await db.weeklyIntentionsDao.getAllIntentions(), hasLength(2));

      await db.weeklyIntentionsDao.deleteAllIntentions();
      expect(await db.weeklyIntentionsDao.getAllIntentions(), isEmpty);
    });
  });
}
