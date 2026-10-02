import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_constants.dart';
import '../utils/date_helpers.dart';
import 'shared_prefs.dart';
import 'today.dart';

/// One policy for everything the app chooses to show, and when.
///
/// Build code only asks questions ([echoAtTop], [echoCardVisible],
/// [hintVisible]); a command records the exposure after the widget actually
/// appeared. All cadence lives here, on top of the same preferences store, so
/// a rebuild is an observation rather than a write.
class Presence {
  Presence(this._prefs, {required DateTime today}) : today = today.toMidnight;

  final SharedPreferences _prefs;

  /// The day this snapshot is for.
  final DateTime today;

  static const echoSeenDatesKey = 'echo_seen_dates';
  static const echoLastShownKey = 'echo_last_shown_date';
  static const firstUseKey = 'first_use_date';
  static const dismissedHintsKey = 'dismissed_feature_hints';

  /// Days the echo card stays quiet after a showing.
  static const echoCooldownDays = 2;

  /// How many times per week the echo may sit at the top of the board.
  static const maxEchoAtTopPerWeek = 2;

  // ── Echo placement ─────────────────────────────────────────

  String get _echoTopKey => 'echo_top_count_${weekStartOf(today).unixSeconds}';

  /// Showings at the top of the board this week.
  int get echoTopCount => _prefs.getInt(_echoTopKey) ?? 0;

  /// Whether the echo may sit at the top; after the cap it moves to the
  /// reflection block at the bottom.
  bool get echoAtTop => echoTopCount < maxEchoAtTopPerWeek;

  /// Records one top placement. A no-op once the weekly cap is reached, so a
  /// repeated command can never inflate the count.
  Future<void> recordEchoTop() async {
    if (!echoAtTop) return;
    await _prefs.setInt(_echoTopKey, echoTopCount + 1);
  }

  // ── Echo card cadence ──────────────────────────────────────

  /// Whether the echo card may be shown today. A fresh install shows it;
  /// after a showing it rests for [echoCooldownDays].
  bool get echoCardVisible {
    final last = _prefs.getInt(echoLastShownKey);
    if (last == null) return true;
    return today.unixSeconds - last >=
        echoCooldownDays * Duration.secondsPerDay;
  }

  /// Records that a memory was actually rendered.
  Future<void> recordEchoCardShown() =>
      _prefs.setInt(echoLastShownKey, today.unixSeconds);

  // ── Seen memories ──────────────────────────────────────────

  /// Dates already shown via «Ещё», so the next visit starts elsewhere.
  Set<int> get seenEchoDates {
    final result = <int>{};
    for (final raw in _prefs.getStringList(echoSeenDatesKey) ?? const []) {
      final value = int.tryParse(raw);
      if (value != null) result.add(value);
    }
    return result;
  }

  /// Remembers [date] as shown, newest first, keeping the list small.
  Future<void> recordEchoSeen(int date) async {
    final current = _prefs.getStringList(echoSeenDatesKey) ?? const [];
    final value = date.toString();
    final next = [value, ...current.where((raw) => raw != value)];
    await _prefs.setStringList(
      echoSeenDatesKey,
      next.take(AppConstants.echoSeenDatesLimit).toList(),
    );
  }

  // ── First use and hints ────────────────────────────────────

  /// The day the app was first used; falls back to [today] until the first
  /// command records it.
  DateTime get firstUseDate =>
      dateFromUnix(_prefs.getInt(firstUseKey) ?? today.unixSeconds);

  int get daysSinceFirstUse => today.difference(firstUseDate).inDays;

  /// Records the first day once. Repeated calls never move it.
  Future<void> recordFirstUse() async {
    if (_prefs.getInt(firstUseKey) != null) return;
    await _prefs.setInt(firstUseKey, today.unixSeconds);
  }

  Set<String> get dismissedHints =>
      (_prefs.getStringList(dismissedHintsKey) ?? const []).toSet();

  /// Whether a feature hint has matured and has not been dismissed yet.
  bool hintVisible({required String key, required int minDays}) =>
      daysSinceFirstUse >= minDays && !dismissedHints.contains(key);

  /// Hides [key] for good.
  Future<void> dismissHint(String key) async {
    final dismissed = _prefs.getStringList(dismissedHintsKey)?.toList() ?? [];
    if (dismissed.contains(key)) return;
    dismissed.add(key);
    await _prefs.setStringList(dismissedHintsKey, dismissed);
  }
}

/// A [Presence] snapshot for today, with the first-use date recorded once.
final presenceProvider = FutureProvider<Presence>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final presence = Presence(
    prefs,
    today: dateFromUnix(ref.watch(todayProvider)),
  );
  await presence.recordFirstUse();
  return presence;
});
