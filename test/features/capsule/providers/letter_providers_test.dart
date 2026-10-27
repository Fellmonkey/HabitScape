import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/capsule/domain/capsule.dart';
import 'package:rythm/features/capsule/providers/letter_providers.dart';

import '../../../fixtures/test_db.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<CapsuleFeed> readFeed() {
    final completer = Completer<CapsuleFeed>();
    final sub = container.listen(capsuleFeedProvider, (prev, next) {
      if (next case AsyncData(:final value) when !completer.isCompleted) {
        completer.complete(value);
      }
    }, fireImmediately: true);
    addTearDown(sub.close);
    return completer.future.timeout(const Duration(seconds: 10));
  }

  test(
    'capsule feed buckets due and upcoming capsules against today',
    () async {
      final today = DateTime.now().toMidnight;
      await db.lettersDao.addLetter(
        deliverAt: today.add(const Duration(days: 30)).unixSeconds,
        body: 'Будущее письмо',
        createdAt: today.unixSeconds,
      );
      await db.lettersDao.addLetter(
        deliverAt: today.subtract(const Duration(days: 1)).unixSeconds,
        body: 'Просроченное письмо',
        createdAt: today.unixSeconds,
      );

      final feed = await readFeed();
      expect(feed.upcoming.map((l) => l.body), ['Будущее письмо']);
      expect(feed.due.map((l) => l.body), ['Просроченное письмо']);
      expect(feed.opened, isEmpty);
    },
  );

  test('capsule feed treats opened capsules as opened, not due', () async {
    final today = DateTime.now().toMidnight;
    final id = await db.lettersDao.addLetter(
      deliverAt: today.subtract(const Duration(days: 7)).unixSeconds,
      body: 'Открытое письмо',
      createdAt: today.unixSeconds,
    );
    await db.lettersDao.markOpened(id, today.unixSeconds);

    final feed = await readFeed();
    expect(feed.opened.map((l) => l.body), ['Открытое письмо']);
    expect(feed.due, isEmpty);
  });

  test(
    'LetterActions create, open, and reply through one command surface',
    () async {
      final actions = container.read(letterActionsProvider.notifier);
      final today = DateTime.now().toMidnight;

      final id = await actions.create(
        deliverAt: today.add(const Duration(days: 7)).unixSeconds,
        body: 'Привет будущему мне',
      );
      final created = (await db.lettersDao.watchLetter(id).first)!;
      expect(created.body, 'Привет будущему мне');
      expect(created.createdAt, today.unixSeconds);

      await actions.markOpened(id);
      final opened = (await db.lettersDao.watchLetter(id).first)!;
      expect(opened.isOpened, isTrue);

      await actions.setReply(id, '  Ответ из будущего  ');
      final replied = (await db.lettersDao.watchLetter(id).first)!;
      expect(replied.reply, 'Ответ из будущего');

      await actions.setReply(id, '   ');
      final cleared = (await db.lettersDao.watchLetter(id).first)!;
      expect(cleared.reply, isNull);
    },
  );
}
