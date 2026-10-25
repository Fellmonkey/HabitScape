import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/debug/debug_data_seeder.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/enums.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/core/domain/completion.dart';

import '../../fixtures/test_db.dart';

/// A clock pinned to a fixed instant — proves the seeder anchors to the
/// clock seam instead of the wall clock.
class _FakeClock implements Clock {
  _FakeClock(this._now);

  final DateTime _now;

  @override
  DateTime now() => _now;
}

void main() {
  group('DebugDataSeeder — настроение', () {
    late AppDatabase db;
    final pinned = DateTime.utc(2026, 10, 15, 14, 30);

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('generates day notes with moods correlated to completion', () async {
      // Seed twice — the second run must wipe the first run's notes too.
      final seeder = DebugDataSeeder(db, clock: _FakeClock(pinned));
      await seeder.seed(debugScenarios.first);
      await seeder.seed(debugScenarios.first);

      final notes = await db.dayNotesDao.getAllNotes();
      expect(notes, isNotEmpty);

      // At least two distinct moods appear in the seeded history.
      final moods = notes.map((n) => n.mood).whereType<DayMood>().toSet();
      expect(moods.length, greaterThanOrEqualTo(2));

      // Some notes carry a moment line, some are mood-only.
      expect(notes.any((n) => n.moment != null), isTrue);
      expect(notes.any((n) => n.moment == null), isTrue);

      // Time quality (1–5) is generated for most rated days.
      final qualities = notes
          .map((n) => n.timeQuality)
          .whereType<int>()
          .toList();
      expect(qualities, isNotEmpty);
      expect(qualities.every((q) => q >= 1 && q <= 5), isTrue);

      // Today (the pinned clock day) is the user's live day note — never
      // pre-filled.
      final today = pinned.toMidnight;
      expect(notes.where((n) => n.date == today.unixSeconds), isEmpty);

      // The current month gets month goals.
      final monthTs = DateTime.utc(today.year, today.month, 1).unixSeconds;
      final goals = await db.monthlyGoalsDao.getGoalsForMonth(monthTs);
      expect(goals, isNotEmpty);

      // Mood correlates with completion: fully-done days score higher
      // on average than days where nothing was done.
      final habits = await db.habitsDao.getActiveHabits();
      final yearStart = today.subtract(const Duration(days: 364));
      final yearEnd = today.add(const Duration(days: 1));
      final logs = await db.habitLogsDao.getLogsInRange(
        yearStart.unixSeconds,
        yearEnd.unixSeconds,
      );
      final monthStart = DateTime.utc(today.year, today.month, 1);
      final points = computeMonthSpreadDays(
        habits: habits,
        logs: logs,
        notes: notes,
        monthStart: monthStart,
      );

      double score(DayMood? m) => switch (m) {
        DayMood.good => 2.0,
        DayMood.ok => 1.0,
        DayMood.bad => 0.0,
        null => 0.0,
      };
      double avgScore(List<MonthSpreadDay> ps) => ps.isEmpty
          ? 0.0
          : ps.map((p) => score(p.mood)).reduce((a, b) => a + b) / ps.length;

      final fullDays = points
          .where((p) => p.expected > 0 && p.ratio >= 0.8)
          .toList();
      final emptyDays = points
          .where((p) => p.expected > 0 && p.ratio == 0)
          .toList();

      if (fullDays.isNotEmpty && emptyDays.isNotEmpty) {
        expect(avgScore(fullDays), greaterThan(avgScore(emptyDays)));
      }
    });

    test('seeding wipes capsules and weekly intentions too', () async {
      await db.lettersDao.addLetter(
        deliverAt: DateTime.utc(2026, 12, 1).unixSeconds,
        body: 'Старая капсула',
        createdAt: DateTime.utc(2026, 10, 1).unixSeconds,
      );
      await db.weeklyIntentionsDao.setIntention(
        weekStartOf(DateTime.now()).unixSeconds,
        'Старое намерение',
      );

      await DebugDataSeeder(db).seed(debugScenarios.first);

      expect(await db.lettersDao.getAllLetters(), isEmpty);
      expect(await db.weeklyIntentionsDao.getAllIntentions(), isEmpty);
    });
  });
}
