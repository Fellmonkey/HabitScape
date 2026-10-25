import '../../../core/database/app_database.dart';
import '../../../core/domain/moment.dart';
import '../../../core/utils/date_helpers.dart';

/// How far back an echo comes from. Chosen automatically, nearest memory
/// first: a year → a month → a week → yesterday. Anything else falls through
/// to [archive] so the card is never empty while there is something to show.
enum EchoHorizon { year, month, week, yesterday, archive }

/// One past day worth remembering.
class EchoMemory {
  const EchoMemory({required this.note, required this.horizon});

  final DayNote note;
  final EchoHorizon horizon;

  DateTime get date => dateFromUnix(note.date);
  String get moment => (note.moment ?? '').trim();
}

/// Everything the echo card needs: ordered memories + whether the archive has
/// any notes at all (so the card can hide on a fresh install instead of
/// showing an empty box).
class EchoFeed {
  const EchoFeed({required this.memories, required this.hasAnyNote});

  final List<EchoMemory> memories;
  final bool hasAnyNote;

  bool get isEmpty => memories.isEmpty;
}

/// Selects past moments to resurface, in display order.
///
/// Pure: no DB, no clock, no prefs. [today] is passed in so tests can pin it.
///
/// Rules:
/// - only notes with a non-empty moment, strictly before [today];
/// - each horizon keeps the newest note inside a small window around the
///   matching past date (a year ago, a month ago, a week ago, yesterday);
/// - remaining notes follow newest → oldest as [EchoHorizon.archive];
/// - [exclude] dates (already shown) are skipped, so the next visit shows
///   something new.
///
/// February 29 is clamped to the last day of the target month, so a leap-day
/// "year ago" never rolls over into March 1.
List<EchoMemory> selectEchoMemories(
  List<DayNote> notes,
  DateTime today, {
  Set<int> exclude = const {},
}) {
  final todayTs = today.toMidnight.unixSeconds;
  final eligible = notes.where((n) {
    return hasMoment(n.moment) && n.date < todayTs && !exclude.contains(n.date);
  }).toList()..sort((a, b) => b.date.compareTo(a.date));

  final targets = <EchoHorizon, (DateTime, int)>{
    EchoHorizon.year: (shiftMonths(today, -12), 3),
    EchoHorizon.month: (shiftMonths(today, -1), 2),
    EchoHorizon.week: (today.toMidnight.subtract(const Duration(days: 7)), 1),
    EchoHorizon.yesterday: (
      today.toMidnight.subtract(const Duration(days: 1)),
      0,
    ),
  };

  final result = <EchoMemory>[];
  final used = <int>{};

  for (final entry in targets.entries) {
    final (target, radius) = entry.value;
    final from = target.subtract(Duration(days: radius)).unixSeconds;
    final to = target.add(Duration(days: radius)).unixSeconds;
    for (final note in eligible) {
      if (used.contains(note.date)) continue;
      if (note.date < from || note.date > to) continue;
      result.add(EchoMemory(note: note, horizon: entry.key));
      used.add(note.date);
      break; // eligible is sorted newest first
    }
  }

  for (final note in eligible) {
    if (used.add(note.date)) {
      result.add(EchoMemory(note: note, horizon: EchoHorizon.archive));
    }
  }

  return result;
}

/// Builds the card's feed: unseen memories first, and — once every date has
/// been seen — familiar memories again instead of an empty card. The one
/// place the "never show nothing" rule lives.
EchoFeed selectEchoFeed(
  List<DayNote> notes,
  DateTime today, {
  required Set<int> seen,
}) {
  var memories = selectEchoMemories(notes, today, exclude: seen);
  if (memories.isEmpty && seen.isNotEmpty) {
    memories = selectEchoMemories(notes, today);
  }
  return EchoFeed(memories: memories, hasAnyNote: notes.isNotEmpty);
}
