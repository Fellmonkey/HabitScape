import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/config/app_constants.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/settings/shared_prefs.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/habits/presentation/screens/habit_detail_screen.dart';
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

  Future<int> insertHabit(String name, {bool isFocus = false}) {
    return db.habitsDao.insertHabit(
      makeHabitCompanion(name: name, isFocus: isFocus),
    );
  }

  /// Opens the detail screen as a pushed route over a trivial host, so the
  /// archive/delete policy's "leave the screen" step is observable.
  Future<void> pumpDetail(WidgetTester tester, int habitId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPrefsProvider.overrideWith((_) async => prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => HabitDetailScreen(habitId: habitId),
                    ),
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

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(K.habitDetailMenu));
    await tester.pumpAndSettle();
  }

  /// Drift stream queries schedule a zero-duration cleanup timer when their
  /// provider is disposed. Dispose the tree inside the test and flush it so
  /// the binding's end-of-test timer invariant sees a clean slate.
  Future<void> disposeTree(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('skip logs today as a skip and confirms it', (tester) async {
    final id = await insertHabit('Бег');
    await pumpDetail(tester, id);

    await openMenu(tester);
    await tester.tap(find.byKey(K.habitDetailSkip));
    await tester.pumpAndSettle();

    final logs = await db.habitLogsDao.getAllLogs();
    expect(logs, hasLength(1));
    expect(logs.single.habitId, id);
    expect(logs.single.date, todayTimestamp());
    expect(logs.single.status, LogStatus.skip);
    expect(logs.single.loggedHour, isNull);
    expect(find.text('Пропуск засчитан. Ничего не сброшено.'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('focus is refused once the cap is full', (tester) async {
    for (var i = 0; i < AppConstants.maxFocusHabits; i++) {
      await insertHabit('Фокус $i', isFocus: true);
    }
    final id = await insertHabit('Цель');
    await pumpDetail(tester, id);

    await openMenu(tester);
    await tester.tap(find.text('Добавить в фокус'));
    await tester.pumpAndSettle();

    expect(find.text('Максимум 5 фокусных привычек'), findsOneWidget);
    expect((await db.habitsDao.getHabit(id)).isFocus, isFalse);
    expect(await db.habitsDao.countFocusHabits(), AppConstants.maxFocusHabits);

    await disposeTree(tester);
  });

  testWidgets('archive hides the habit and returns to the host', (
    tester,
  ) async {
    final id = await insertHabit('Архивная привычка');
    await pumpDetail(tester, id);

    await openMenu(tester);
    await tester.tap(find.text('Архивировать'));
    await tester.pumpAndSettle();

    expect((await db.habitsDao.getHabit(id)).isArchived, isTrue);
    expect(find.text('Архивная привычка'), findsNothing);
    expect(find.text('open'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('delete asks first; cancelling keeps the habit', (tester) async {
    final id = await insertHabit('Удаляемая привычка');
    await pumpDetail(tester, id);

    await openMenu(tester);
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(find.text('Удалить привычку?'), findsOneWidget);

    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(find.text('Удаляемая привычка'), findsOneWidget);
    expect((await db.habitsDao.getHabit(id)).isArchived, isFalse);

    await disposeTree(tester);
  });

  testWidgets('delete confirmed removes the habit and returns to the host', (
    tester,
  ) async {
    await insertHabit('Удаляемая привычка');
    await pumpDetail(tester, 1);

    await openMenu(tester);
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    expect(await db.habitsDao.getAllHabits(), isEmpty);
    expect(find.text('Удаляемая привычка'), findsNothing);
    expect(find.text('open'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('history tab shows its empty state when no logs exist', (
    tester,
  ) async {
    final id = await insertHabit('Без истории');
    await pumpDetail(tester, id);

    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();

    expect(find.text('Нет записей'), findsOneWidget);

    await disposeTree(tester);
  });
}
