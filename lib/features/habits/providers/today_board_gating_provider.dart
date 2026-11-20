import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'habit_streams.dart';

/// Thresholds for the greenhouse's newcomer-friendly header controls.
const greenHouseHistoryMinHabits = 3;
const greenhouseToggleMinGroupHabits = 5;

class TodayBoardGating {
  const TodayBoardGating({
    required this.canSeeHistory,
    required this.canSeeToggle,
  });

  final bool canSeeHistory;
  final bool canSeeToggle;
}

/// Derived from the live habit count so the screen never decides its own
/// visibility rules.
final todayBoardGatingProvider = Provider<TodayBoardGating>((ref) {
  final count = ref.watch(activeHabitsProvider).value?.length ?? 0;
  return TodayBoardGating(
    canSeeHistory: count >= greenHouseHistoryMinHabits,
    canSeeToggle: count >= greenhouseToggleMinGroupHabits,
  );
});
