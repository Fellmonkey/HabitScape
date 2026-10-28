import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/domain/habit_lifecycle.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/presentation/widgets/habit_lifecycle_section.dart';
import 'package:rythm/features/habits/providers/habit_lifecycle_providers.dart';

import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders age, stability and totals', (tester) async {
    final lifecycle = HabitLifecycle(
      habit: makeHabit(
        id: 1,
        name: 'Бег',
        createdAt: DateTime.now().toMidnight
            .subtract(const Duration(days: 90))
            .unixSeconds,
      ),
      ageDays: 90,
      doneCount: 50,
      expectedCount: 60,
      stabilityPct: 83.33,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitLifecycleDetailProvider.overrideWith(
            (ref, id) async => lifecycle,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HabitLifecycleSection(habitId: 1),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Жизненный цикл'), findsOneWidget);
    expect(find.text('3 мес'), findsOneWidget); // habitAgeLabel(90)
    expect(find.text('50 из 60'), findsOneWidget);
    expect(find.text('Стабильность'), findsOneWidget);
    expect(find.text('83%'), findsOneWidget);
  });

  testWidgets('hides when the habit has no lifecycle data', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          habitLifecycleDetailProvider.overrideWith((ref, id) async => null),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: HabitLifecycleSection(habitId: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Жизненный цикл'), findsNothing);
  });
}
