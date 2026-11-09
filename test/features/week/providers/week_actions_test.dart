import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/settings/week_answer.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/week/providers/week_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saveIntentionAndAnswer persists both stores in one command', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final db = createTestDatabase();
    addTearDown(db.close);

    // A Tuesday to exercise the Monday-closes-previous-week rule.
    final monday = DateTime.utc(2026, 11, 9);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWith((_) async => prefs),
        todayProvider.overrideWith(() => FixedToday(monday.unixSeconds)),
      ],
    );
    addTearDown(container.dispose);

    // On a Monday the summary closes the previous week; the intention is
    // carried into the fresh (current) week.
    final closingWeek = weekStartOf(monday).subtract(const Duration(days: 7));

    await container
        .read(weekIntentionActionsProvider.notifier)
        .saveIntentionAndAnswer(
          weekStart: closingWeek,
          intention: 'Бег по вторникам',
        );

    final saved = await db.weeklyIntentionsDao.getForWeek(
      weekStartOf(monday).unixSeconds,
    );
    expect(saved?.intention, 'Бег по вторникам');

    // The answered marker is written for the closing week, not the current one.
    final store = WeekAnswerStore(prefs);
    expect(store.lastAnsweredWeek, closingWeek.unixSeconds);
  });

  test(
    'answerWeek invalidates weekSummaryProvider so reads never go stale',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final db = createTestDatabase();
      addTearDown(db.close);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
      );
      addTearDown(container.dispose);

      final before = await container.read(weekSummaryProvider.future);
      expect(before.isAnswered, isFalse);

      await container
          .read(weekIntentionActionsProvider.notifier)
          .answerWeek(before.weekStart);

      // Without invalidation this would still be the cached pre-answer snapshot.
      final after = await container.read(weekSummaryProvider.future);
      expect(after.isAnswered, isTrue);
    },
  );
}
