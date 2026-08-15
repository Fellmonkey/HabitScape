import 'package:drift/drift.dart' hide isNull;
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

  group('Stats screen (Статистика)', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    testWidgets('opens via bottom nav and shows summary + heatmap', (
      tester,
    ) async {
      db = await pumpApp(tester);

      // Seed a habit and a done log for today + a mood note.
      final habitId = await db.habitsDao.insertHabit(
        HabitsCompanion(
          name: const Value('Бег'),
          seedArchetype: const Value('oak'),
          frequencyType: const Value('daily'),
          frequencyValue: const Value('{}'),
          timeOfDay: const Value('anytime'),
          createdAt: Value(DateTime.utc(2026, 1, 1).unixSeconds),
        ),
      );
      final today = DateTime.now().toMidnight;
      await db.habitLogsDao.markDone(habitId, today.unixSeconds, 8);
      await db.dayNotesDao.upsertNote(
        today.unixSeconds,
        moment: 'Отличный день',
        mood: DayMood.good,
      );

      // Open the stats tab.
      await tester.tap(find.byKey(K.navStats));
      await tester.pumpAndSettle();

      expect(find.byKey(K.statsTitle), findsOneWidget);
      expect(find.text('Активность за год'), findsOneWidget);
      expect(find.byKey(K.statsHeatmap), findsOneWidget);

      // Week trend sits right under the header.
      expect(find.byKey(K.statsWeekTrend), findsOneWidget);

      // Correlation section (further down the page). The stats screen has
      // two Scrollables (the vertical list + the heatmap's horizontal one),
      // so the outer list must be named explicitly.
      final statsList = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.scrollUntilVisible(
        find.text('Настроение и выполнение'),
        200,
        scrollable: statsList,
      );
      expect(find.byKey(K.statsCorrelation), findsOneWidget);

      // Mood counts + rhythm section.
      await tester.scrollUntilVisible(
        find.text('Ритм недели'),
        200,
        scrollable: statsList,
      );
      expect(find.byKey(K.statsRhythm), findsOneWidget);
      expect(find.text('Настроение за месяц'), findsOneWidget);
    });

    testWidgets('empty state shows no-data message', (tester) async {
      db = await pumpApp(tester);

      await tester.tap(find.byKey(K.navStats));
      await tester.pumpAndSettle();

      expect(find.byKey(K.statsTitle), findsOneWidget);
      // Empty-state hints instead of a ranking.
      expect(
        find.text(
          'Отмечай привычки — здесь появится сравнение с прошлой неделей.',
        ),
        findsOneWidget,
      );
      expect(find.text('Привычки за месяц'), findsNothing);
    });
  });
}
