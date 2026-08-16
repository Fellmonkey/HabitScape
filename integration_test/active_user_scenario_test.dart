import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/utils/date_helpers.dart';

import 'helpers/pump_app.dart';

/// Simulates what an active user sees when opening the app: 5 habits with
/// different frequencies and time-of-day slots, plus today's logs.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Active-user scenario', () {
    late AppDatabase db;

    tearDown(() async {
      await db.close();
    });

    /// Inserts 5 habits with today's logs for the Greenhouse screen.
    Future<void> seedHabits(AppDatabase db) async {
      final now = DateTime.now().toMidnight;

      final habitIds = <String, int>{};

      Future<int> insert(String name, String timeOfDay, String frequency) {
        return db.habitsDao.insertHabit(
          HabitsCompanion(
            name: Value(name),
            icon: const Value('check'),
            frequencyType: Value(frequency),
            frequencyValue: const Value('{}'),
            timeOfDay: Value(timeOfDay),
            createdAt: Value(DateTime.utc(2026, 1, 1).unixSeconds),
          ),
        );
      }

      habitIds['Morning Run'] = await insert('Morning Run', 'morning', 'daily');
      habitIds['Read Books'] = await insert('Read Books', 'evening', 'daily');
      habitIds['Workout'] = await insert('Workout', 'afternoon', 'daily');
      habitIds['No Smoking'] = await insert('No Smoking', 'anytime', 'daily');
      habitIds['Meditation'] = await insert('Meditation', 'morning', 'daily');

      // Today's logs: Morning Run done, Workout skip, rest pending.
      await db.habitLogsDao.markDone(
        habitIds['Morning Run']!,
        now.unixSeconds,
        7,
      );
      await db.habitLogsDao.markSkip(habitIds['Workout']!, now.unixSeconds);
    }

    testWidgets('Greenhouse shows all 5 habits grouped by time-of-day', (
      tester,
    ) async {
      db = await pumpApp(tester);
      await seedHabits(db);
      await tester.pumpAndSettle();

      // All 5 habit names visible.
      expect(find.text('Morning Run'), findsOneWidget);
      expect(find.text('Read Books'), findsOneWidget);
      expect(find.text('Workout'), findsOneWidget);
      expect(find.text('No Smoking'), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);

      // Group headers present.
      expect(find.text('Утро'), findsOneWidget); // Morning Run + Meditation
      expect(find.text('День'), findsOneWidget); // Workout
      expect(find.text('Вечер'), findsOneWidget); // Read Books
      // No Smoking → anytime → "Весь день" group
      expect(find.text('Весь день'), findsOneWidget);
    });
  });
}
