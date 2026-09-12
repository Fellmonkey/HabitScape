import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';

import 'helpers/pump_app.dart';

/// Helper: opens the create-habit sheet, fills in [name], optionally picks a
/// [timeOfDay] chip under «Настроить», and taps the create button.
Future<void> createHabit(
  WidgetTester tester, {
  required String name,
  String? timeOfDay,
}) async {
  await tester.tap(find.byKey(K.fabCreateHabit));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(K.habitNameField), name);

  if (timeOfDay != null) {
    // Time of day lives under the collapsed «Настроить» section.
    await tester.tap(find.text('Настроить'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(timeOfDay).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(timeOfDay).last);
    await tester.pumpAndSettle();
  }

  await tester.ensureVisible(find.byKey(K.habitCreateButton));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(K.habitCreateButton));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Single habit lifecycle', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets('create → appears in list → mark done → check icon', (
      tester,
    ) async {
      db = await pumpApp(tester);

      // Initially empty.
      expect(find.byKey(K.emptyHabitsMessage), findsOneWidget);

      // Create a habit.
      await createHabit(tester, name: 'Утренняя пробежка', timeOfDay: 'Утро');

      // Empty message gone, habit card visible.
      expect(find.byKey(K.emptyHabitsMessage), findsNothing);
      expect(find.text('Утренняя пробежка'), findsOneWidget);
      expect(find.text('Утро'), findsOneWidget); // group header

      // Tap the check circle to mark done.
      await tester.tap(find.byKey(K.habitCheck(1)));
      await tester.pumpAndSettle();

      // The check icon should now be visible (done state).
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('skip today from habit detail', (tester) async {
      db = await pumpApp(tester);
      await createHabit(tester, name: 'Медитация');

      // Open the habit detail.
      await tester.tap(find.text('Медитация'));
      await tester.pumpAndSettle();

      // «Пропустить сегодня» lives in the detail menu — no hidden gestures.
      await tester.tap(find.byKey(K.habitDetailMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.habitDetailSkip));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Pause icon should appear (skip state).
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('delete from habit detail removes it from the list', (
      tester,
    ) async {
      db = await pumpApp(tester);
      await createHabit(tester, name: 'Удали меня');

      expect(find.text('Удали меня'), findsOneWidget);

      await tester.tap(find.text('Удали меня'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(K.habitDetailMenu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить').last);
      await tester.pumpAndSettle();

      // Confirm in the dialog.
      await tester.tap(find.widgetWithText(TextButton, 'Удалить'));
      await tester.pumpAndSettle();

      // Habit gone, empty state returns.
      expect(find.text('Удали меня'), findsNothing);
      expect(find.byKey(K.emptyHabitsMessage), findsOneWidget);
    });
  });
}
