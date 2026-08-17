import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/keys.dart';

import 'helpers/pump_app.dart';

/// Helper: opens the create-habit sheet, fills in [name], picks [timeOfDay]
/// chip label, and taps the create button.
Future<void> createHabit(
  WidgetTester tester, {
  required String name,
  String timeOfDay = 'Весь день',
}) async {
  await tester.tap(find.byKey(K.fabCreateHabit));
  await tester.pumpAndSettle();

  // Enter habit name.
  await tester.enterText(find.byKey(K.habitNameField), name);

  // Pick time of day chip.
  await tester.tap(find.text(timeOfDay).last);
  await tester.pumpAndSettle();

  // Scroll down inside the DraggableScrollableSheet to reach the button.
  await tester.drag(find.text('Семечко'), const Offset(0, -200));
  await tester.pumpAndSettle();

  // Tap the create button.
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

    testWidgets('swipe left → skip via bottom sheet', (tester) async {
      db = await pumpApp(tester);
      await createHabit(tester, name: 'Медитация');

      // Fling the Dismissible left to trigger confirmDismiss.
      final dismissible = find.byKey(const ValueKey('habit_1'));
      expect(dismissible, findsOneWidget);

      await tester.fling(dismissible, const Offset(-500, 0), 1500);
      await tester.pumpAndSettle();

      // The swipe menu appears. Tap "Respectful skip".
      expect(find.byKey(K.swipeSkip), findsOneWidget);
      await tester.tap(find.byKey(K.swipeSkip));
      await tester.pumpAndSettle();

      // Pause icon should appear (skip state).
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('swipe left → delete removes habit from list', (tester) async {
      db = await pumpApp(tester);
      await createHabit(tester, name: 'Удали меня');

      expect(find.text('Удали меня'), findsOneWidget);

      final dismissible = find.byKey(const ValueKey('habit_1'));
      await tester.fling(dismissible, const Offset(-500, 0), 1500);
      await tester.pumpAndSettle();

      // Tap "Delete".
      expect(find.byKey(K.swipeDelete), findsOneWidget);
      await tester.tap(find.byKey(K.swipeDelete));
      await tester.pumpAndSettle();

      // Habit gone, empty state returns.
      expect(find.text('Удали меня'), findsNothing);
      expect(find.byKey(K.emptyHabitsMessage), findsOneWidget);
    });
  });
}
