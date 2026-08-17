import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';

import 'helpers/pump_app.dart';

/// Helper: opens the create-habit sheet, fills in [name], picks [timeOfDay]
/// chip label, and taps the create button.
Future<void> _createHabit(
  WidgetTester tester, {
  required String name,
  String timeOfDay = 'Весь день',
  String frequency = 'Каждый день',
}) async {
  await tester.tap(find.byKey(K.fabCreateHabit));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(K.habitNameField), name);

  // Pick time of day chip.
  await tester.tap(find.text(timeOfDay).last);
  await tester.pumpAndSettle();

  // Pick frequency chip.
  await tester.tap(find.text(frequency).last);
  await tester.pumpAndSettle();

  // Scroll down inside the DraggableScrollableSheet to reach the button.
  await tester.drag(find.text('Семечко'), const Offset(0, -200));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(K.habitCreateButton));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-habit day session with time-of-day grouping', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'create 4 habits in different ToD groups and verify grouping + progress',
      (tester) async {
        db = await pumpApp(tester);

        // Create habits across different time-of-day groups.
        await _createHabit(tester, name: 'Зарядка', timeOfDay: 'Утро');
        await _createHabit(tester, name: 'Читать', timeOfDay: 'Вечер');
        await _createHabit(
          tester,
          name: 'Обед без телефона',
          timeOfDay: 'День',
        );
        await _createHabit(tester, name: 'Дневник', timeOfDay: 'Вечер');

        // All four habits are visible.
        expect(find.text('Зарядка'), findsOneWidget);
        expect(find.text('Читать'), findsOneWidget);
        expect(find.text('Обед без телефона'), findsOneWidget);
        expect(find.text('Дневник'), findsOneWidget);

        // Group headers appear.
        expect(find.text('Утро'), findsOneWidget);
        expect(find.text('День'), findsOneWidget);
        expect(find.text('Вечер'), findsOneWidget);

        // Progress is 0% — none done yet.
        expect(find.text('0%'), findsOneWidget);
      },
    );

    testWidgets('marking habits updates progress ring correctly', (
      tester,
    ) async {
      db = await pumpApp(tester);

      await _createHabit(tester, name: 'Привычка A', timeOfDay: 'Утро');
      await _createHabit(tester, name: 'Привычка B', timeOfDay: 'Утро');

      // 0/2 done = 0%.
      expect(find.text('0%'), findsOneWidget);

      // Mark first habit done.
      await tester.tap(find.byKey(K.habitCheck(1)));
      await tester.pumpAndSettle();

      // 1/2 = 50%.
      expect(find.text('50%'), findsOneWidget);

      // Mark second habit done.
      await tester.tap(find.byKey(K.habitCheck(2)));
      await tester.pumpAndSettle();

      // 2/2 = 100%.
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets(
      'hide-completed toggle hides done habits and shows them again',
      (tester) async {
        db = await pumpApp(tester);

        await _createHabit(tester, name: 'Видимая', timeOfDay: 'Утро');
        await _createHabit(tester, name: 'Скрываемая', timeOfDay: 'Утро');

        // Mark "Hidden" as done.
        await tester.tap(find.byKey(K.habitCheck(2)));
        await tester.pumpAndSettle();

        // Both still visible.
        expect(find.text('Видимая'), findsOneWidget);
        expect(find.text('Скрываемая'), findsOneWidget);

        // Tap hide-completed toggle.
        await tester.tap(find.byKey(K.hideCompletedToggle));
        await tester.pumpAndSettle();

        // Done habit hidden, the other remains.
        expect(find.text('Видимая'), findsOneWidget);
        expect(find.text('Скрываемая'), findsNothing);

        // Toggle back.
        await tester.tap(find.byKey(K.hideCompletedToggle));
        await tester.pumpAndSettle();

        expect(find.text('Скрываемая'), findsOneWidget);
      },
    );

    testWidgets('"Mark All" in a group marks all habits done', (tester) async {
      db = await pumpApp(tester);

      await _createHabit(tester, name: 'Групповая A', timeOfDay: 'Утро');
      await _createHabit(tester, name: 'Групповая B', timeOfDay: 'Утро');
      await _createHabit(tester, name: 'Другая', timeOfDay: 'Вечер');

      // 0% initially.
      expect(find.text('0%'), findsOneWidget);

      // Tap "All" (mark all) for the "Morning" group.
      await tester.tap(find.byKey(K.markAllGroup('Утро')));
      await tester.pumpAndSettle();

      // Two out of three done (morning group marked, evening untouched).
      // 2/3 ≈ 67%.
      expect(find.text('67%'), findsOneWidget);

      // Both morning habits should show check icon.
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    });
  });
}
