import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/habits/presentation/widgets/habit_form_sheet.dart';
import 'package:rythm/shared/widgets/app_sheets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSheet(WidgetTester tester, {Habit? habit}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => AppSheets.show<int>(
                    context,
                    builder: (_) => HabitFormSheet(habit: habit),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The save button starts below the fold; scroll the form's list until it
  /// is built, then tap it.
  Future<void> tapSave(WidgetTester tester) async {
    final button = find.byKey(K.habitCreateButton);
    final list = find
        .descendant(
          of: find.byType(HabitFormSheet),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(button, 240, scrollable: list);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('a blank name creates nothing and keeps the sheet open', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tapSave(tester);

    expect(await db.habitsDao.getAllHabits(), isEmpty);
    expect(find.byKey(K.habitCreateButton), findsOneWidget);
  });

  testWidgets('a template fills the payload the form saves', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Выпить воду'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    final habits = await db.habitsDao.getAllHabits();
    expect(habits, hasLength(1));
    final habit = habits.single;
    expect(habit.name, 'Выпить воду');
    expect(habit.icon, 'water');
    expect(habit.frequencyType, 'daily');
    expect(habit.timeOfDay, 'morning');
    expect(find.text('Новая привычка'), findsNothing);
  });

  testWidgets('editing saves the changed fields onto the existing habit', (
    tester,
  ) async {
    final id = await db.habitsDao.insertHabit(
      makeHabitCompanion(name: 'Старое имя', icon: 'check'),
    );
    final habit = await db.habitsDao.getHabit(id);
    await pumpSheet(tester, habit: habit);

    expect(find.text('Редактировать'), findsOneWidget);
    await tester.enterText(find.byKey(K.habitNameField), 'Новое имя');
    await tapSave(tester);

    final updated = await db.habitsDao.getHabit(id);
    expect(updated.name, 'Новое имя');
    expect(updated.icon, 'check');
    expect(find.text('Редактировать'), findsNothing);
  });
}
