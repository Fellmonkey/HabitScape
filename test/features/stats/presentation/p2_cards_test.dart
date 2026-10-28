import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/utils/time_bucket.dart';
import 'package:rythm/features/stats/domain/habit_lifecycle.dart';
import 'package:rythm/features/stats/domain/time_suggestion.dart';
import 'package:rythm/features/stats/presentation/widgets/archive_card.dart';
import 'package:rythm/features/stats/presentation/widgets/habits_card.dart';
import 'package:rythm/features/stats/presentation/widgets/time_suggestion_card.dart';
import 'package:rythm/features/stats/providers/habit_lifecycle_providers.dart';

import '../../../fixtures/test_factories.dart';

HabitLifecycle _lifecycle({
  required int id,
  required String name,
  bool archived = false,
  int ageDays = 90,
  int done = 50,
  int expected = 60,
}) {
  return HabitLifecycle(
    habit: makeHabit(
      id: id,
      name: name,
      isArchived: archived,
      createdAt: DateTime.now().toMidnight
          .subtract(Duration(days: ageDays))
          .unixSeconds,
    ),
    ageDays: ageDays,
    doneCount: done,
    expectedCount: expected,
    stabilityPct: done / expected * 100,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitLifecycleProvider.overrideWith(
            (ref) async => [
              _lifecycle(id: 1, name: 'Бег'),
              _lifecycle(id: 2, name: 'Чтение', archived: true, ageDays: 120),
            ],
          ),
          timeSuggestionsProvider.overrideWith(
            (ref) async => [
              TimeSuggestion(
                habit: makeHabit(id: 1, name: 'Бег'),
                actualBucket: TimeBucket.morning,
                sampleSize: 14,
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('habits card shows active habits with age and stability', (
    tester,
  ) async {
    await pump(tester, const HabitsCard());
    expect(find.byKey(K.statsHabits), findsOneWidget);
    expect(find.text('Привычки'), findsOneWidget);
    expect(find.text('Бег'), findsOneWidget);
    expect(find.text('3 мес · 83%'), findsOneWidget); // 90 days → 3 мес
    expect(find.text('Чтение'), findsNothing);
  });

  testWidgets('archive card shows retired habits with their life span', (
    tester,
  ) async {
    await pump(tester, const ArchiveCard());
    expect(find.byKey(K.statsArchive), findsOneWidget);
    expect(find.text('Архив'), findsOneWidget);
    expect(find.text('Чтение'), findsOneWidget);
    expect(find.text('жила 4 мес · 83% · 50 ×'), findsOneWidget);
    expect(find.text('Бег'), findsNothing);
  });

  testWidgets('time suggestion card shows the hint', (tester) async {
    await pump(tester, const TimeSuggestionCard());
    expect(find.byKey(K.statsSuggestion), findsOneWidget);
    expect(find.text('Подсказка'), findsOneWidget);
    expect(find.textContaining('Бег: чаще отмечаешь утром'), findsOneWidget);
    expect(find.textContaining('n=14'), findsOneWidget);
  });
}
