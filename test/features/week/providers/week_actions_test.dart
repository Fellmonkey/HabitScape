import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/settings/week_answer.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/week/providers/week_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saveIntentionAndAnswer persists both stores in one command', () async {
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

    final weekStart = weekStartOf(DateTime.utc(2026, 10, 27));
    // Closing week in a Monday summary is the previous one.
    final closingWeek = weekStart.subtract(const Duration(days: 7));

    await container
        .read(weekIntentionActionsProvider.notifier)
        .saveIntentionAndAnswer(
          weekStart: closingWeek,
          intention: 'Бег по вторникам',
        );

    final saved = await db.weeklyIntentionsDao.getForWeek(
      weekStart.unixSeconds,
    );
    expect(saved?.intention, 'Бег по вторникам');

    // The answered marker is written for the closing week, not the current one.
    final store = WeekAnswerStore(prefs);
    expect(store.lastAnsweredWeek, closingWeek.unixSeconds);
  });
}
