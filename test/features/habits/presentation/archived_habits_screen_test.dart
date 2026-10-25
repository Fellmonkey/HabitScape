import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/habits/presentation/screens/archived_habits_screen.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: AppTheme.light, home: ArchivedHabitsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Flushes drift's zero-duration cleanup timers (same workaround as the
  /// greenhouse tests) so dispose never leaves a pending timer behind.
  Future<void> flushDispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('shows the empty state when nothing is archived', (tester) async {
    await pump(tester);

    expect(find.text('Архив пуст'), findsOneWidget);

    await flushDispose(tester);
  });

  testWidgets('lists archived habits and hides active ones', (tester) async {
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Архивная', isArchived: true),
    );
    await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Активная', isArchived: false),
    );

    await pump(tester);

    expect(find.text('Архивная'), findsOneWidget);
    expect(find.text('Активная'), findsNothing);

    await flushDispose(tester);
  });

  testWidgets('restore moves the habit back to active', (tester) async {
    final id = await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Верну', isArchived: true),
    );

    await pump(tester);
    await tester.tap(find.byTooltip('Восстановить'));
    await tester.pumpAndSettle();

    expect(find.text('Архив пуст'), findsOneWidget);
    expect((await db.habitsDao.getHabit(id)).isArchived, isFalse);

    await flushDispose(tester);
  });

  testWidgets('permanent delete requires confirmation', (tester) async {
    final id = await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Удалю', isArchived: true),
    );

    await pump(tester);
    await tester.tap(find.byTooltip('Удалить навсегда'));
    await tester.pumpAndSettle();

    // The dialog asks first; cancel keeps the habit.
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Удалю'), findsOneWidget);
    expect((await db.habitsDao.getHabit(id)).isArchived, isTrue);

    // Confirm deletes permanently.
    await tester.tap(find.byTooltip('Удалить навсегда'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Архив пуст'), findsOneWidget);
    expect(db.habitsDao.getHabit(id), throwsStateError);

    await flushDispose(tester);
  });
}
