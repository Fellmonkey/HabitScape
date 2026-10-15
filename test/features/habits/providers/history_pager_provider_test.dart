import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/providers/history_pager_provider.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

class _FixedToday extends TodayNotifier {
  _FixedToday(this.date);

  final DateTime date;

  @override
  int build() => date.toMidnight.unixSeconds;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.utc(2026, 10, 15);

  late AppDatabase db;
  late int habitId;
  late ProviderContainer container;

  setUp(() async {
    db = createTestDatabase();
    habitId = await db.habitsDao.insertHabit(makeHabitCompanion(name: 'Бег'));
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        todayProvider.overrideWith(() => _FixedToday(today)),
      ],
    );
    addTearDown(container.dispose);
  });

  tearDown(() async {
    await db.close();
  });

  /// Keeps the auto-disposed family member alive for the test body.
  HistoryPager pager() {
    container.listen(historyPagerProvider(habitId), (_, _) {});
    return container.read(historyPagerProvider(habitId).notifier);
  }

  Future<HistoryPagerState> firstPage() async {
    container.listen(historyPagerProvider(habitId), (_, _) {});
    return container.read(historyPagerProvider(habitId).future);
  }

  Future<void> addLog(DateTime date) {
    return db.habitLogsDao.upsertLog(
      makeLogCompanion(habitId: habitId, date: date.unixSeconds, loggedHour: 8),
    );
  }

  test('first page flattens its month and logs newest-first', () async {
    await addLog(DateTime.utc(2026, 9, 2));
    await addLog(DateTime.utc(2023, 1, 4));

    final state = await firstPage();

    expect(state.isEmpty, isFalse);
    expect(state.hasMore, isTrue);
    expect(state.isLoading, isFalse);
    expect(
      state.rows.map(
        (row) => switch (row) {
          HistoryMonthRow(:final month) => 'month ${month.year}-${month.month}',
          HistoryLogRow(:final log) => 'log ${log.date}',
        },
      ),
      ['month 2026-9', 'log ${DateTime.utc(2026, 9, 2).unixSeconds}'],
    );
  });

  test('loadMore appends older months and then exhausts', () async {
    await addLog(DateTime.utc(2026, 9, 2));
    await addLog(DateTime.utc(2023, 1, 4));

    await firstPage();
    final p = pager();
    expect(
      container.read(historyPagerProvider(habitId)).requireValue.rows,
      hasLength(2),
    );

    await p.loadMore();

    final state = container.read(historyPagerProvider(habitId)).requireValue;
    expect(state.rows, hasLength(4));
    expect(state.hasMore, isFalse);
    expect(state.rows.whereType<HistoryMonthRow>().map((r) => r.month.year), [
      2026,
      2023,
    ]);

    // Asking again after exhaustion is a no-op.
    await p.loadMore();
    expect(
      container.read(historyPagerProvider(habitId)).requireValue.rows,
      hasLength(4),
    );
  });

  test('no logs exhausts immediately with no rows', () async {
    final state = await firstPage();

    expect(state.isEmpty, isTrue);
    expect(state.isExhausted, isTrue);
    expect(state.hasMore, isFalse);
    expect(state.isLoading, isFalse);
  });
}
