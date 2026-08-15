import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/keys.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import 'helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Day moment (Момент дня)', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets('empty hint → save moment + mood → displayed', (tester) async {
      db = await pumpApp(tester);

      // The card shows the empty-state hint.
      expect(find.byKey(K.dayMomentCard), findsOneWidget);
      expect(find.text('Что запомнилось сегодня?'), findsOneWidget);

      // Open the sheet.
      await tester.tap(find.byKey(K.dayMomentCard));
      await tester.pumpAndSettle();

      // Enter a moment and pick a mood.
      await tester.enterText(
        find.byKey(K.dayMomentField),
        'Встретил друга у залива',
      );
      await tester.tap(find.text('Хороший день'));
      await tester.pumpAndSettle();

      // Pick time quality (level 5 — «Максимально»).
      await tester.tap(find.byKey(K.timeQualityLevel(5)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(K.dayMomentSave));
      await tester.pumpAndSettle();

      // Card now shows the moment and mood label.
      expect(find.text('Встретил друга у залива'), findsOneWidget);
      expect(find.text('Хороший день'), findsOneWidget);

      // Persisted in the DB.
      final note = await db.dayNotesDao.getNoteForDate(todayTimestamp());
      expect(note, isNotNull);
      expect(note!.moment, 'Встретил друга у залива');
      expect(note.timeQuality, 5);
    });

    testWidgets('mood-only note and editing an existing note', (tester) async {
      db = await pumpApp(tester);

      // Save mood-only note.
      await tester.tap(find.byKey(K.dayMomentCard));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Плохой день'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.dayMomentSave));
      await tester.pumpAndSettle();

      expect(find.text('День отмечен · добавь момент'), findsOneWidget);
      expect(find.text('Плохой день'), findsOneWidget);

      // Reopen and edit: add a moment.
      await tester.tap(find.byKey(K.dayMomentCard));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(K.dayMomentField),
        'Голова болела весь день',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.dayMomentSave));
      await tester.pumpAndSettle();

      expect(find.text('Голова болела весь день'), findsOneWidget);
      expect(find.text('Плохой день'), findsOneWidget);

      final note = await db.dayNotesDao.getNoteForDate(todayTimestamp());
      expect(note!.moment, 'Голова болела весь день');
    });

    testWidgets('clearing the note returns to the empty hint', (tester) async {
      db = await pumpApp(tester);

      // Seed a note directly.
      await db.dayNotesDao.upsertNote(
        todayTimestamp(),
        moment: 'Красивый закат',
        mood: null,
      );
      await tester.pumpAndSettle();

      expect(find.text('Красивый закат'), findsOneWidget);

      // Open and clear the field, save.
      await tester.tap(find.byKey(K.dayMomentCard));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(K.dayMomentField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(K.dayMomentSave));
      await tester.pumpAndSettle();

      expect(find.text('Что запомнилось сегодня?'), findsOneWidget);
      expect(await db.dayNotesDao.getNoteForDate(todayTimestamp()), isNull);
    });
  });

  group('Month spread (Разворот месяца)', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets('opens from greenhouse, shows grid + moments, edits a day', (
      tester,
    ) async {
      db = await pumpApp(tester);

      final now = DateTime.now();
      final today = now.toMidnight;

      // Seed a daily habit done today + a day note with a moment.
      final habitId = await db.habitsDao.insertHabit(
        HabitsCompanion(
          name: const Value('Зарядка'),
          seedArchetype: const Value('oak'),
          frequencyType: const Value('daily'),
          frequencyValue: const Value('{}'),
          timeOfDay: const Value('anytime'),
          createdAt: Value(
            DateTime.utc(now.year, now.month - 1, 28).unixSeconds,
          ),
        ),
      );
      await db.habitLogsDao.markDone(habitId, today.unixSeconds, 8);
      await db.dayNotesDao.upsertNote(
        today.unixSeconds,
        moment: 'Отличный день',
        mood: DayMood.good,
        timeQuality: 5,
      );
      await tester.pumpAndSettle();

      // Open the spread from the greenhouse header.
      await tester.tap(find.byKey(K.openMonthSpread));
      await tester.pumpAndSettle();

      // Month title + grid + today's cell + the moment feed.
      expect(find.byKey(K.monthSpreadTitle), findsOneWidget);
      expect(find.byKey(K.monthSpreadGrid), findsOneWidget);
      expect(find.byKey(K.monthSpreadDay(today.day)), findsOneWidget);
      expect(find.byKey(K.monthSpreadMoments), findsOneWidget); // feed header
      expect(find.text('Отличный день'), findsOneWidget);

      // Tap today's cell → day editor opens prefilled.
      await tester.tap(find.byKey(K.monthSpreadDay(today.day)));
      await tester.pumpAndSettle();
      expect(find.text('Что запомнилось в этот день?'), findsOneWidget);
      // The moment is prefilled in the sheet's text field.
      final field = tester.widget<TextField>(find.byKey(K.dayMomentField));
      expect(field.controller!.text, 'Отличный день');

      // Close the sheet so the test finishes cleanly.
      await tester.tapAt(const Offset(20, 20)); // barrier
      await tester.pumpAndSettle();

      // Pop back to the greenhouse.
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('navigates months with arrows and returns to today', (
      tester,
    ) async {
      db = await pumpApp(tester);

      await tester.tap(find.byKey(K.openMonthSpread));
      await tester.pumpAndSettle();

      final title = find.byKey(K.monthSpreadTitle);
      final currentTitle = (tester.widget<Text>(title)).data!;

      await tester.tap(find.byKey(K.monthSpreadNext));
      await tester.pumpAndSettle();
      final nextTitle = (tester.widget<Text>(title)).data!;
      expect(nextTitle, isNot(currentTitle));

      // «Сегодня» returns to the current month.
      await tester.tap(find.byKey(K.monthSpreadToday));
      await tester.pumpAndSettle();
      expect((tester.widget<Text>(title)).data, currentTitle);
    });

    testWidgets('swipes horizontally to switch months', (tester) async {
      db = await pumpApp(tester);

      await tester.tap(find.byKey(K.openMonthSpread));
      await tester.pumpAndSettle();

      final title = find.byKey(K.monthSpreadTitle);
      final currentTitle = (tester.widget<Text>(title)).data!;

      // Swipe left → next month.
      await tester.fling(
        find.byKey(K.monthSpreadGrid),
        const Offset(-400, 0),
        1200,
      );
      await tester.pumpAndSettle();
      final nextTitle = (tester.widget<Text>(title)).data!;
      expect(nextTitle, isNot(currentTitle));

      // Swipe right → back to the current month.
      await tester.fling(
        find.byKey(K.monthSpreadGrid),
        const Offset(400, 0),
        1200,
      );
      await tester.pumpAndSettle();
      expect((tester.widget<Text>(title)).data, currentTitle);
    });
  });

  group('Month goals (Цели месяца)', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets('add and toggle a goal', (tester) async {
      db = await pumpApp(tester);

      // Empty card is visible.
      expect(find.byKey(K.monthGoalsCard), findsOneWidget);

      // Add a goal.
      await tester.tap(find.byKey(K.monthGoalsAdd));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(K.monthGoalsField), 'Снять 4 видео');
      await tester.tap(find.byKey(K.monthGoalsSave));
      await tester.pumpAndSettle();

      expect(find.text('Снять 4 видео'), findsOneWidget);

      // Toggle it done.
      final now = DateTime.now();
      final monthTs = DateTime.utc(now.year, now.month, 1).unixSeconds;
      final goals = await db.monthlyGoalsDao.getGoalsForMonth(monthTs);
      expect(goals, hasLength(1));
      expect(goals.first.isDone, isFalse);

      await tester.tap(find.byKey(K.monthGoal(goals.first.id)));
      await tester.pumpAndSettle();

      final after = await db.monthlyGoalsDao.getGoalsForMonth(monthTs);
      expect(after.first.isDone, isTrue);
    });
  });
}
