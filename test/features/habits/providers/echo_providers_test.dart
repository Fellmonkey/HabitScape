import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/domain/echo.dart';
import 'package:rythm/features/habits/providers/echo_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWith((_) async => prefs),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<EchoFeed> readFeed() {
    final completer = Completer<EchoFeed>();
    final sub = container.listen(echoFeedProvider, (prev, next) {
      if (next case AsyncData(:final value) when !completer.isCompleted) {
        completer.complete(value);
      }
    }, fireImmediately: true);
    addTearDown(sub.close);
    return completer.future.timeout(const Duration(seconds: 10));
  }

  test(
    'echo feed skips already-seen dates, then falls back to familiar',
    () async {
      final today = DateTime.now().toMidnight;
      final yesterday = today.subtract(const Duration(days: 1)).unixSeconds;
      final longAgo = today.subtract(const Duration(days: 300)).unixSeconds;

      await db.dayNotesDao.upsertNote(
        yesterday,
        moment: 'Вчерашняя заметка',
        mood: DayMood.good,
      );
      await db.dayNotesDao.upsertNote(
        longAgo,
        moment: 'Старая заметка',
        mood: DayMood.ok,
      );

      // Nothing seen yet — both memories are eligible.
      final all = await readFeed();
      expect(all.hasAnyNote, isTrue);
      expect(
        all.memories.map((m) => m.note.date),
        containsAll([yesterday, longAgo]),
      );

      // Mark both as seen — the provider must fall back to a familiar memory
      // instead of going blank.
      await prefs.setStringList('echo_seen_dates', [
        yesterday.toString(),
        longAgo.toString(),
      ]);
      container.invalidate(echoFeedProvider);
      final afterSeen = await readFeed();
      expect(afterSeen.hasAnyNote, isTrue);
      expect(afterSeen.memories, isNotEmpty);
    },
  );

  test('echo feed hides on a fresh install with no notes', () async {
    final feed = await readFeed();
    expect(feed.hasAnyNote, isFalse);
    expect(feed.memories, isEmpty);
  });
}
