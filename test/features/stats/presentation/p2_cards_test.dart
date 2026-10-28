import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/domain/habit_lifecycle.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/stats/presentation/widgets/archive_card.dart';
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

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    List<HabitLifecycle>? lifecycles,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitLifecycleProvider.overrideWith((ref) async {
            return lifecycles ??
                [
                  _lifecycle(id: 1, name: 'Бег'),
                  _lifecycle(
                    id: 2,
                    name: 'Чтение',
                    archived: true,
                    ageDays: 120,
                  ),
                ];
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('archive card shows retired habits with their life span', (
    tester,
  ) async {
    await pump(tester, const ArchiveCard());
    expect(find.byKey(K.statsArchive), findsOneWidget);
    expect(find.text('Архив'), findsOneWidget);
    expect(find.text('Чтение'), findsOneWidget);
    expect(find.text('жила 4 мес · 83% · 50 выполнений'), findsOneWidget);
    expect(find.text('Бег'), findsNothing);
  });

  testWidgets('archive card with nothing archived shows a header and hint', (
    tester,
  ) async {
    await pump(tester, const ArchiveCard(), lifecycles: const []);
    expect(find.byKey(K.statsArchive), findsOneWidget);
    expect(find.text('Архив'), findsOneWidget);
    expect(find.textContaining('Архив пуст'), findsOneWidget);
  });
}
