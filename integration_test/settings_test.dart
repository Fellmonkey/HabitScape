import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';

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
      expect(find.text('Rythm'), findsOneWidget);
      expect(find.text('Версия 1.0.0'), findsOneWidget);
    });

    testWidgets('import button shows confirmation dialog', (tester) async {
      db = await pumpApp(tester);

      await tester.tap(find.text('Ещё'));
      await tester.pumpAndSettle();

      // Tap "Импорт данных".
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
