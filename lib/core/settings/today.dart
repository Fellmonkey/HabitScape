import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/date_helpers.dart';

/// Current calendar day as a unix midnight timestamp. Re-invalidates itself
/// shortly after midnight so today-scoped providers never go stale overnight.
final todayProvider = NotifierProvider<TodayNotifier, int>(TodayNotifier.new);

/// [todayProvider] as a calendar date for presentation code.
///
/// Widgets and presentation providers read this instead of calling
/// `DateTime.now()` so a midnight tick reaches every today-scoped label.
final todayDateProvider = Provider<DateTime>((ref) {
  return dateFromUnix(ref.watch(todayProvider));
});

class TodayNotifier extends Notifier<int> {
  Timer? _midnightTimer;

  @override
  int build() {
    final now = DateTime.now();
    final today = now.toMidnight;
    // Refresh a moment after midnight (buffer for clock/timer jitter).
    _midnightTimer?.cancel();
    _midnightTimer = Timer(
      today.add(const Duration(days: 1)).difference(now) +
          const Duration(seconds: 1),
      ref.invalidateSelf,
    );
    ref.onDispose(() => _midnightTimer?.cancel());
    return today.unixSeconds;
  }
}
