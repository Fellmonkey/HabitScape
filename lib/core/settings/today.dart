import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/date_helpers.dart';

/// The single clock seam of the app: every "what time is it" — reads and
/// writes alike — goes through [clockProvider] so tests can pin the date and
/// the hour together. The wall clock lives in exactly one adapter.
abstract interface class Clock {
  DateTime now();
}

/// The production clock: the real wall clock.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// The one seam for the current instant. Presentation code reads this instead
/// of calling `DateTime.now()` directly.
final clockProvider = Provider<Clock>((ref) => const SystemClock());

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
    final now = ref.read(clockProvider).now();
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
