import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/database/app_database.dart';
import 'package:rythm/core/database/database_provider.dart';
import 'package:rythm/core/settings/today.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/providers/habit_providers.dart';

import '../../../fixtures/test_db.dart';
import '../../../fixtures/test_factories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('todayProvider returns today\'s midnight timestamp', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(todayProvider), todayTimestamp());
  });

  test('todayProvider stays stable across rebuilds within the same day', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = container.read(todayProvider);
    // A rebuild (e.g. the midnight self-invalidation) must still resolve to
    // the same calendar day while the clock hasn't crossed midnight.
    container.invalidate(todayProvider);
    expect(container.read(todayProvider), first);
  });

  test('todayDateProvider is the calendar view of the same clock', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(todayDateProvider),
      dateFromUnix(container.read(todayProvider)),
    );
  });

  test('today-based providers derive their date from todayProvider', () async {
    final db = createTestDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final ts = container.read(todayProvider);
    expect(ts, todayTimestamp());

    // todayLogsProvider/todayDayNoteProvider stay alive (non-autoDispose)
    // and react to the day value without ever needing a manual refresh.
    final logsReady = Completer<List<HabitLog>>();
    final logsSub = container.listen(todayLogsProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        if (!logsReady.isCompleted) logsReady.complete(value);
      }
    }, fireImmediately: true);
    addTearDown(logsSub.close);
    expect(await logsReady.future, isEmpty);

    final noteReady = Completer<DayNote?>();
    final noteSub = container.listen(todayDayNoteProvider, (_, next) {
      if (next case AsyncData(:final value)) {
        if (!noteReady.isCompleted) noteReady.complete(value);
      }
    }, fireImmediately: true);
    addTearDown(noteSub.close);
    expect(await noteReady.future, isNull);
  });
}
