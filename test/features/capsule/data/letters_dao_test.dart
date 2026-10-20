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
      final createdAt = DateTime.utc(2026, 10, 1).unixSeconds;
      final id = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'Привет из октября',
        createdAt: createdAt,
      );

      expect(id, greaterThan(0));
      final all = await db.lettersDao.getAllLetters();
      expect(all, hasLength(1));
      expect(all.first.body, 'Привет из октября');
      expect(all.first.deliverAt, DateTime.utc(2026, 12, 1).unixSeconds);
      expect(all.first.createdAt, createdAt);
      expect(all.first.isOpened, isFalse);
    });

    test(
      'watchAllLetters returns every capsule, newest created first',
      () async {
        final older = await db.lettersDao.addLetter(
          deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
          body: 'Старое',
          createdAt: DateTime.utc(2026, 10, 1).unixSeconds,
        );
        final newer = await db.lettersDao.addLetter(
          deliverAt: DateTime.utc(2026, 12, 2).unixSeconds,
          body: 'Новое',
          createdAt: DateTime.utc(2026, 10, 2).unixSeconds,
        );

        final all = await db.lettersDao.watchAllLetters().first;

        expect(all.map((l) => l.id), [newer, older]);
      },
    );

    test('markOpened sets isOpened and openedAt', () async {
      final id = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'Что-то',
        createdAt: DateTime.utc(2026, 10, 1).unixSeconds,
      );
      final openedAt = DateTime.utc(2026, 12, 1).unixSeconds;

      await db.lettersDao.markOpened(id, openedAt);

      final all = await db.lettersDao.getAllLetters();
      expect(all.single.isOpened, isTrue);
      expect(all.single.openedAt, openedAt);
    });

    test('setReply records and clears the reply', () async {
      final id = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'Что-то',
        createdAt: DateTime.utc(2026, 10, 1).unixSeconds,
      );

      await db.lettersDao.setReply(id, 'Я справился!');
      final all = await db.lettersDao.getAllLetters();
      expect(all.single.reply, 'Я справился!');

      await db.lettersDao.setReply(id, null);
      expect((await db.lettersDao.getAllLetters()).single.reply, isNull);
    });

    test('deleteLetter removes one row; deleteAll clears everything', () async {
      final a = await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'A',
        createdAt: DateTime.utc(2026, 10, 1).unixSeconds,
      );
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 2).unixSeconds,
        body: 'B',
        createdAt: DateTime.utc(2026, 10, 2).unixSeconds,
      );

      await db.lettersDao.deleteLetter(a);
      expect(await db.lettersDao.getAllLetters(), hasLength(1));

      await db.lettersDao.deleteAllLetters();
      expect(await db.lettersDao.getAllLetters(), isEmpty);
    });
  });
}
