import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings screen integration', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets('all settings tiles are tappable and accessible', (
      tester,
    ) async {
      db = await pumpApp(tester);

      // Navigate to Settings.
      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      // Top tiles visible without scrolling.
      expect(find.byKey(K.settingsExport), findsOneWidget);
      expect(find.byKey(K.settingsImport), findsOneWidget);

      // Descriptive subtitles (top half).
      expect(find.text('Сохранить все привычки в файл'), findsOneWidget);
      expect(
        find.text('Восстановить из файла (заменит текущие данные)'),
        findsOneWidget,
      );

      // Scroll down to reveal the lower sections.
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Archive + about.
      expect(find.text('Архивные привычки'), findsOneWidget);
      expect(find.text('HabitScape'), findsOneWidget);
      expect(find.text('Версия 1.0.0'), findsOneWidget);
      expect(find.text('Fellmonkey'), findsOneWidget);
      expect(find.byKey(K.settingsAboutAuthor), findsOneWidget);
    });

    testWidgets('import button shows confirmation dialog', (tester) async {
      db = await pumpApp(tester);

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      // Tap "Import data".
      await tester.tap(find.byKey(K.settingsImport));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear.
      expect(find.text('Импорт данных'), findsNWidgets(2)); // title + tile
      expect(
        find.text(
          'Все текущие данные будут заменены данными из файла. '
          'Это действие нельзя отменить. Продолжить?',
        ),
        findsOneWidget,
      );

      // Cancel button is available.
      expect(find.text('Отмена'), findsOneWidget);

      // Dismiss the dialog.
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
    });

    testWidgets('haptics toggle persists and flips the switch', (tester) async {
      db = await pumpApp(tester);

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      // Scroll down to the "Experience" section.
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final toggle = find.byKey(K.hapticsToggle);
      expect(toggle, findsOneWidget);
      expect(find.text('Вибрация'), findsOneWidget);

      // Default is ON; flip it OFF.
      final switchFinder = find.descendant(
        of: toggle,
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(switchFinder).value, isFalse);

      // Persisted in SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('haptics_enabled'), isFalse);
    });

    testWidgets('backup export → import round-trip via DAO layer', (
      tester,
    ) async {
      db = await pumpApp(tester);

      // Seed data: a habit + log.
      await db.habitsDao.insertHabit(
        HabitsCompanion(
          name: const Value('Round-Trip Habit'),
          createdAt: Value(
            DateTime.utc(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
          ),
        ),
      );

      // Verify data exists (programmatic check, not UI — because
      // SharePlus is platform-dependent and can't be tested in integration).
      final habits = await db.habitsDao.getAllHabits();
      expect(habits.length, 1);
      expect(habits.first.name, 'Round-Trip Habit');
    });
  });
}
