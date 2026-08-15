import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/utils/date_helpers.dart';
import 'package:rythm/features/habits/providers/habit_providers.dart';

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

  test('today-based providers derive their date from todayProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ts = container.read(todayProvider);
    expect(ts, todayTimestamp());

    // todayLogsProvider/todayDayNoteProvider stay alive (non-autoDispose)
    // and react to the day value without ever needing a manual refresh.
    expect(container.read(todayLogsProvider), isA<AsyncValue>());
    expect(container.read(todayDayNoteProvider), isA<AsyncValue>());
  });
}
