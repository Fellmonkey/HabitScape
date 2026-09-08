import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import '../../../fixtures/test_db.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('LettersDao', () {
    test('addLetter returns an id and persists the row', () async {
      final id = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'Привет из октября',
      );

      expect(id, greaterThan(0));
      final all = await db.lettersDao.getAllLetters();
      expect(all, hasLength(1));
      expect(all.first.body, 'Привет из октября');
      expect(all.first.deliverAt, DateTime.utc(2026, 12, 1).unixSeconds);
      expect(all.first.createdAt, todayTimestamp());
      expect(all.first.isOpened, isFalse);
    });

    test('watchUpcoming only returns future, unopened letters', () async {
      final today = DateTime.utc(2026, 11, 1).unixSeconds;
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 10, 30).unixSeconds, // past
        body: 'Прошлое',
      );
      final futureId = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds, // future
        body: 'Будущее',
      );
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds, // future, opened
        body: 'Открытое',
      );
      await db.lettersDao.markOpened(futureId, today);

      final upcoming = await db.lettersDao.watchUpcoming(today).first;
      expect(upcoming, hasLength(1));
      expect(upcoming.single.body, 'Открытое');
    });

    test('watchDue only returns arrived, unopened letters', () async {
      final today = DateTime.utc(2026, 11, 1).unixSeconds;
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 10, 30).unixSeconds, // past
        body: 'Прошлое',
      );
      final openedId = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 10, 29).unixSeconds, // past, opened
        body: 'Открытое',
      );
      await db.lettersDao.markOpened(openedId, today);
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds, // future
        body: 'Будущее',
      );

      final due = await db.lettersDao.watchDue(today).first;
      expect(due, hasLength(1));
      expect(due.single.body, 'Прошлое');
    });

    test('markOpened sets isOpened and openedAt', () async {
      final id = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'Что-то',
      );
      final openedAt = DateTime.utc(2026, 12, 1).unixSeconds;

      await db.lettersDao.markOpened(id, openedAt);

      final all = await db.lettersDao.getAllLetters();
      expect(all.single.isOpened, isTrue);
      expect(all.single.openedAt, openedAt);
    });

    test('deleteLetter removes one row; deleteAll clears everything', () async {
      final a = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'A',
      );
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 2).unixSeconds,
        body: 'B',
      );

      await db.lettersDao.deleteLetter(a);
      expect(await db.lettersDao.getAllLetters(), hasLength(1));

      await db.lettersDao.deleteAllLetters();
      expect(await db.lettersDao.getAllLetters(), isEmpty);
    });
  });
}
