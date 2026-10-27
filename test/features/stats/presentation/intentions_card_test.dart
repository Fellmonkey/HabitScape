import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/presentation/widgets/intentions_card.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';
import '../../../fixtures/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final today = DateTime.utc(2026, 10, 28);

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          todayProvider.overrideWith(() => FixedToday(today.unixSeconds)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: IntentionsCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('invites to answer the week summary when empty', (tester) async {
    await pumpCard(tester);
    expect(find.byKey(K.statsIntentions), findsOneWidget);
    expect(find.textContaining('Отвечай на итог недели'), findsOneWidget);
  });

  testWidgets('shows intentions with the reality of the following week', (
    tester,
  ) async {
    final createdAt = today.subtract(const Duration(days: 60)).unixSeconds;
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Бег', createdAt: createdAt),
    );
    // The week after the intention is fully done.
    final weekStart = today.subtract(const Duration(days: 21));
    await db.habitLogsDao.upsertLogs([
      for (var d = 0; d < 7; d++)
        makeLogCompanion(
          habitId: 1,
          date: weekStart.add(Duration(days: 7 + d)).unixSeconds,
        ),
    ]);
    await db.weeklyIntentionsDao.setIntention(
      weekStart.unixSeconds,
      'Бег по вторникам',
    );

    await pumpCard(tester);

    expect(find.byKey(K.statsIntentions), findsOneWidget);
    expect(find.text('«Бег по вторникам»'), findsOneWidget);
    expect(find.textContaining('Следующая неделя: 100%'), findsOneWidget);
  });
}
