import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/today.dart';
import '../domain/habit_history.dart';

/// One rendered row in a habit's history: a month header followed by that
/// month's logs. Flattening lives here so the widget does no index math.
sealed class HistoryRow {
  const HistoryRow();
}

final class HistoryMonthRow extends HistoryRow {
  const HistoryMonthRow(this.month);

  final HabitHistoryMonth month;
}

final class HistoryLogRow extends HistoryRow {
  const HistoryLogRow(this.log);

  final HabitLog log;
}

/// Immutable snapshot of the history pager: the flat rows plus whether a
/// page is in flight and whether older history may still exist.
class HistoryPagerState {
  const HistoryPagerState({
    required this.rows,
    required this.isLoading,
    required this.isExhausted,
  });

  final List<HistoryRow> rows;
  final bool isLoading;
  final bool isExhausted;

  bool get isEmpty => rows.isEmpty;
  bool get hasMore => !isExhausted;
}

/// Paging state for one habit's history.
///
/// Owns the [HabitHistory] instance, the first page load, and the flat row
/// order. The screen watches [HistoryPagerState] and asks for more; it never
/// touches a cursor or maps a sliver index to a month/log pair.
class HistoryPager extends AsyncNotifier<HistoryPagerState> {
  HistoryPager(this.habitId);

  final int habitId;

  HabitHistory? _history;

  @override
  Future<HistoryPagerState> build() async {
    final history = HabitHistory(
      habitId: habitId,
      store: ref.watch(historyStoreProvider),
      now: ref.watch(todayDateProvider),
    );
    _history = history;
    await history.loadNextPage();
    return _snapshot(history);
  }

  /// Loads the next chunk of older history. No-op while a page is loading,
  /// after exhaustion, or before the first page resolves.
  Future<void> loadMore() async {
    final history = _history;
    if (history == null || history.isLoading || history.isExhausted) return;

    state = AsyncData(_snapshot(history, isLoading: true));
    try {
      await history.loadNextPage();
      if (!ref.mounted) return;
      state = AsyncData(_snapshot(history));
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      state = AsyncError(error, stackTrace);
    }
  }

  HistoryPagerState _snapshot(HabitHistory history, {bool isLoading = false}) {
    return HistoryPagerState(
      rows: [
        for (final month in history.months) ...[
          HistoryMonthRow(month),
          for (final log in month.logs) HistoryLogRow(log),
        ],
      ],
      isLoading: isLoading || history.isLoading,
      isExhausted: history.isExhausted,
    );
  }
}

/// History pager for one habit, auto-disposed with the detail screen.
final historyPagerProvider = AsyncNotifierProvider.autoDispose
    .family<HistoryPager, HistoryPagerState, int>(HistoryPager.new);
