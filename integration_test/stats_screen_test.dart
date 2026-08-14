import 'package:drift/drift.dart' hide isNull;
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

      // Habit ranking lists the seeded habit.
      expect(find.text('Бег'), findsOneWidget);
      expect(find.text('Настроение за месяц'), findsOneWidget);
    });

    testWidgets('empty state shows no-data message', (tester) async {
      db = await pumpApp(tester);

      await tester.tap(find.byKey(K.navStats));
      await tester.pumpAndSettle();

      expect(find.byKey(K.statsTitle), findsOneWidget);
      expect(find.text('Пока нет данных'), findsOneWidget);
    });
  });
}
