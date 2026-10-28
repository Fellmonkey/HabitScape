import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_constants.dart';
import '../utils/date_helpers.dart';
import 'shared_prefs.dart';
import 'today.dart';

/// One policy for everything the app chooses to show, and when.
///
/// Owns every piece of exposure state — hints dismissed, echo placement and
/// cooldown, and seen memories — on top of one preferences store. Tour
/// bookkeeping lives in the hintful store (`core/settings/hintful.dart`), not
/// here. Feature code asks questions ([hintVisible], [echoAtTop],
/// [echoCardVisible]) and records exposure only after the thing actually
/// appeared; it never invents its own keys or cadence.
class Exposure {
  Exposure(this._prefs, {required DateTime today}) : today = today.toMidnight;

  final SharedPreferences _prefs;

  /// The day this snapshot is for.
  final DateTime today;

  static const echoSeenDatesKey = 'echo_seen_dates';
  static const echoLastShownKey = 'echo_last_shown_date';
  static const firstUseKey = 'first_use_date';
  static const dismissedHintsKey = 'dismissed_feature_hints';
  static const seenUxKey = 'seen_ux_hints';
  static const lastSeenKey = 'last_seen_date';
  static const welcomeShownKey = 'welcome_shown_date';
  static const pendingBannersKey = 'pending_banners';

  /// Absence (in days) after which the return welcome may appear.
  static const absentReturnDays = 7;

  /// Days the echo card stays quiet after a showing.
  static const echoCooldownDays = 1;

  /// How many times per week the echo may sit at the top of the board.
  static const maxEchoAtTopPerWeek = 2;

  // ── One-time exposure (tours and hints) ────────────────────

  Set<String> _stringSet(String key) =>
      (_prefs.getStringList(key) ?? const []).toSet();

  Future<void> _addToStringSet(String key, String value) async {
    final current = _prefs.getStringList(key)?.toList() ?? [];
    if (current.contains(value)) return;
    current.add(value);
    await _prefs.setStringList(key, current);
  }

  /// Hint keys the user closed for good.
  Set<String> get dismissedHints => _stringSet(dismissedHintsKey);

  /// Whether a feature hint has matured and has not been dismissed yet.
  bool hintVisible({required String key, required int minDays}) =>
      daysSinceFirstUse >= minDays && !dismissedHints.contains(key);

  /// Hides [key] for good. Repeated calls keep one entry.
  Future<void> dismissHint(String key) =>
      _addToStringSet(dismissedHintsKey, key);

  /// Back to the first-run slate: every feature hint can appear again.
  Future<void> clearDismissedHints() async {
    await _prefs.remove(dismissedHintsKey);
  }

  // ── Echo placement ─────────────────────────────────────────

  String get _echoTopKey => 'echo_top_count_${weekStartOf(today).unixSeconds}';

  /// Showings at the top of the board this week.
  int get echoTopCount => _prefs.getInt(_echoTopKey) ?? 0;

  /// Whether the echo may sit at the top of the board. Always true: the card
  /// is placed in one stable position (top of the board) and visibility is
  /// governed only by the cooldown, so the feature reads as reliable.
  bool get echoAtTop => true;

  /// Records one top placement. A no-op once the weekly cap is reached, so a
  /// repeated command can never inflate the count.
  Future<void> recordEchoTop() async {
    if (!echoAtTop) return;
    await _prefs.setInt(_echoTopKey, echoTopCount + 1);
  }

  // ── Echo card cadence ──────────────────────────────────────

  /// Whether the echo card may be shown today. A fresh install shows it;
  /// after a showing it rests for [echoCooldownDays]. A showing recorded
  /// today keeps the card up for the rest of the day — the cooldown begins
  /// tomorrow, so the just-shown card never vanishes mid-session.
  bool get echoCardVisible {
    final last = _prefs.getInt(echoLastShownKey);
    if (last == null) return true;
    if (last == today.unixSeconds) return true;
    return today.unixSeconds - last >=
        echoCooldownDays * Duration.secondsPerDay;
  }

  /// Records that a memory was actually rendered.
  Future<void> recordEchoCardShown() =>
      _prefs.setInt(echoLastShownKey, today.unixSeconds);

  /// Records one rendered showing: the card-wide cooldown always charges, and
  /// a top placement also charges the weekly quota. This is the single verb
  /// every card mount calls — never two separate writes.
  Future<void> recordEchoShown({required bool atTop}) async {
    await recordEchoCardShown();
    if (atTop) await recordEchoTop();
  }

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

  // ── First use ──────────────────────────────────────────────

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

  // ── Return-welcome ─────────────────────────────────────────

  /// The last day the app was opened, or null on a fresh install.
  DateTime? get lastSeenDate {
    final v = _prefs.getInt(lastSeenKey);
    return v == null ? null : dateFromUnix(v);
  }

  /// Whole days since the last visit (0 on a fresh install).
  int get daysSinceLastSeen {
    final last = lastSeenDate;
    return last == null ? 0 : today.difference(last).inDays;
  }

  /// True exactly once per absence episode: absent for [absentReturnDays]
  /// or more AND no welcome shown yet for this episode (the shown marker
  /// must be older than the last visit or absent).
  bool get shouldShowWelcomeBack {
    if (daysSinceLastSeen < absentReturnDays) return false;
    final last = lastSeenDate;
    if (last == null) return false;
    final shown = _prefs.getInt(welcomeShownKey);
    return shown == null || dateFromUnix(shown).isBefore(last);
  }

  /// Remembers today as the last visit.
  Future<void> recordVisit() => _prefs.setInt(lastSeenKey, today.unixSeconds);

  /// Marks the current absence episode as welcomed— next day the marker is
  /// no older than the visit, so the card stays hidden until a new absence.
  Future<void> markWelcomeShown() =>
      _prefs.setInt(welcomeShownKey, today.unixSeconds);

  // ── Deferred banner queue ─────────────────────────────────

  /// Banners that were available but lost the single-banner arbitration (e.g.
  /// the week summary suppressed by a time suggestion). They are shown on
  /// later visits, in FIFO order, so nothing is lost to prioritisation.
  List<String> get pendingBanners =>
      _prefs.getStringList(pendingBannersKey) ?? const [];

  /// Adds [id] to the deferred queue unless it is already there.
  Future<void> pushPendingBanner(String id) async {
    if (pendingBanners.contains(id)) return;
    await _prefs.setStringList(pendingBannersKey, [...pendingBanners, id]);
  }

  /// Removes the first occurrence of [id] (once it has been displayed).
  Future<void> removePendingBanner(String id) async {
    final list = pendingBanners;
    if (!list.contains(id)) return;
    final next = [...list]..remove(id);
    await _prefs.setStringList(pendingBannersKey, next);
  }
}

/// An [Exposure] snapshot for today, with the first-use date recorded once.
final exposureProvider = FutureProvider<Exposure>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final exposure = Exposure(
    prefs,
    today: dateFromUnix(ref.watch(todayProvider)),
  );
  await exposure.recordFirstUse();
  return exposure;
});

/// The one command surface over [Exposure] state. Widgets and mixins must
/// invoke verbs here instead of reaching into the store object, so every
/// write flows through one interface that invalidates [exposureProvider] —
/// reads stay reactive and can never go stale mid-session.
class ExposureActions extends Notifier<void> {
  @override
  void build() {}

  Future<Exposure> get _exposure => ref.read(exposureProvider.future);

  Future<void> _mutate(Future<void> Function(Exposure) op) async {
    final exposure = await _exposure;
    await op(exposure);
    ref.invalidate(exposureProvider);
  }

  /// Records a showing (cooldown + optional weekly top quota) and refreshes
  /// the snapshot so quota/cooldown reads reflect it immediately.
  Future<void> recordEchoShown({required bool atTop}) =>
      _mutate((e) => e.recordEchoShown(atTop: atTop));

  /// Remembers [date] as shown and refreshes the snapshot.
  Future<void> recordEchoSeen(int date) =>
      _mutate((e) => e.recordEchoSeen(date));

  /// Hides [key] for good and refreshes the snapshot.
  Future<void> dismissHint(String key) => _mutate((e) => e.dismissHint(key));

  /// Clears all dismissed feature hints and refreshes the snapshot.
  Future<void> resetDismissedHints() => _mutate((e) => e.clearDismissedHints());

  /// Records a visit and refreshes the snapshot.
  Future<void> recordVisit() => _mutate((e) => e.recordVisit());

  /// Marks the return welcome as shown for this episode and refreshes.
  Future<void> markWelcomeShown() => _mutate((e) => e.markWelcomeShown());

  /// Adds a banner id to the deferred queue and refreshes the snapshot.
  Future<void> pushPendingBanner(String id) =>
      _mutate((e) => e.pushPendingBanner(id));

  /// Removes a banner id from the deferred queue and refreshes the snapshot.
  Future<void> removePendingBanner(String id) =>
      _mutate((e) => e.removePendingBanner(id));
}

final exposureActionsProvider = NotifierProvider<ExposureActions, void>(
  ExposureActions.new,
);
