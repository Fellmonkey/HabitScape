import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/shared_prefs.dart';
import '../domain/echo.dart';
import 'habit_providers.dart';

/// Dates already shown by the echo card, stored newest first.
const echoSeenDatesKey = 'echo_seen_dates';

/// Keep the list small — 30 memories is enough to avoid obvious repeats.
const _maxSeenDates = 30;

/// The echo card's data: past moments ordered for display.
///
/// Recomputes when any note changes (a save, an import, an edit), and skips
/// dates the user has already seen via «Ещё».
final echoFeedProvider = StreamProvider<EchoFeed>((ref) {
  final notesStream = ref.watch(dayNotesDaoProvider).watchAllNotes();
  final prefsFuture = ref.watch(sharedPrefsProvider.future);

  return notesStream.asyncMap((notes) async {
    final prefs = await prefsFuture;
    final seen = _seenDates(prefs);
    final today = DateTime.now();

    var memories = selectEchoMemories(notes, today, exclude: seen);
    // A tiny archive would go blank once every date is seen — show a familiar
    // memory instead of nothing.
    if (memories.isEmpty && seen.isNotEmpty) {
      memories = selectEchoMemories(notes, today);
    }

    return EchoFeed(memories: memories, hasAnyNote: notes.isNotEmpty);
  });
});

/// Remembers that [date] was shown so the next visit surfaces another memory.
Future<void> rememberEchoShown(SharedPreferences prefs, int date) async {
  final current = prefs.getStringList(echoSeenDatesKey) ?? <String>[];
  final next = [
    date.toString(),
    ...current.where((raw) => raw != date.toString()),
  ];
  await prefs.setStringList(
    echoSeenDatesKey,
    next.take(_maxSeenDates).toList(),
  );
}

Set<int> _seenDates(SharedPreferences prefs) {
  final result = <int>{};
  for (final raw in prefs.getStringList(echoSeenDatesKey) ?? const <String>[]) {
    final value = int.tryParse(raw);
    if (value != null) result.add(value);
  }
  return result;
}
