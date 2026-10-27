import '../../../core/database/app_database.dart';
import '../../../core/utils/date_helpers.dart';

/// Preset delays for a new capsule. The first is the default — one month,
/// matching the promise "a sentence to yourself in a month".
enum CapsulePreset {
  week(0, 7, 'Через неделю'),
  month(1, 0, 'Через месяц'),
  halfYear(6, 0, 'Через 6 месяцев'),
  year(12, 0, 'Через год');

  const CapsulePreset(this.months, this.days, this.label);

  /// How many months ahead the capsule opens (0 for day-based presets).
  final int months;

  /// How many days ahead the capsule opens (0 for month-based presets).
  final int days;

  final String label;
}

/// Lifecycle of a capsule relative to today.
enum CapsuleStatus { upcoming, due, opened }

/// Where a capsule sits today.
CapsuleStatus capsuleStatus(Letter letter, DateTime today) {
  if (letter.isOpened) return CapsuleStatus.opened;
  final deliverAt = dateFromUnix(letter.deliverAt);
  if (!deliverAt.isAfter(today.toMidnight)) return CapsuleStatus.due;
  return CapsuleStatus.upcoming;
}

/// The capsule feed for one day: upcoming / due / opened buckets plus the day
/// boundary they were computed against.
///
/// Both the greenhouse card and the capsule screen read this one feed, so the
/// status rule and the clock live in exactly one place.
class CapsuleFeed {
  const CapsuleFeed({
    required this.today,
    required this.upcoming,
    required this.due,
    required this.opened,
  });

  /// Groups a flat list into the three buckets. Upcoming and due are ordered
  /// by delivery (nearest / oldest waiting first); opened keeps the incoming
  /// newest-created-first order from the DAO.
  factory CapsuleFeed.fromLetters(List<Letter> letters, DateTime today) {
    final day = today.toMidnight;
    final upcoming = <Letter>[];
    final due = <Letter>[];
    final opened = <Letter>[];
    for (final letter in letters) {
      switch (capsuleStatus(letter, day)) {
        case CapsuleStatus.upcoming:
          upcoming.add(letter);
        case CapsuleStatus.due:
          due.add(letter);
        case CapsuleStatus.opened:
          opened.add(letter);
      }
    }
    int byDelivery(Letter a, Letter b) => a.deliverAt.compareTo(b.deliverAt);
    upcoming.sort(byDelivery);
    due.sort(byDelivery);
    return CapsuleFeed(
      today: day,
      upcoming: List.unmodifiable(upcoming),
      due: List.unmodifiable(due),
      opened: List.unmodifiable(opened),
    );
  }

  /// The day this feed was computed for — never the wall clock.
  final DateTime today;
  final List<Letter> upcoming;
  final List<Letter> due;
  final List<Letter> opened;

  bool get isEmpty => upcoming.isEmpty && due.isEmpty && opened.isEmpty;
}

/// Whole days until delivery (0 or negative once it is due).
int daysUntil(Letter letter, DateTime today) {
  return dateFromUnix(letter.deliverAt).difference(today.toMidnight).inDays;
}

/// The delivery date for a capsule written on [from] with [preset].
DateTime deliveryDate(DateTime from, CapsulePreset preset) {
  final midnight = from.toMidnight;
  if (preset.days > 0) {
    return midnight.add(Duration(days: preset.days));
  }
  return shiftMonths(midnight, preset.months);
}

/// "a month ago" / "half a year ago" / "a year ago", derived from the actual
/// gap between writing and delivery so any custom timing still reads well.
String wroteAgoLabel(Letter letter) {
  final days = dateFromUnix(
    letter.deliverAt,
  ).difference(dateFromUnix(letter.createdAt)).inDays;
  if (days >= 320) return 'год назад';
  if (days >= 150) return 'полгода назад';
  return 'месяц назад';
}

/// Cumulative capsule statistics: how many were sent, opened and replied to,
/// and when the next locked one opens. Pure — derived only from the feed's
/// letters, never from the wall clock.
class CapsuleStats {
  const CapsuleStats({
    required this.sent,
    required this.opened,
    required this.replied,
    this.nextDueInDays,
  });

  /// Total capsules ever written.
  final int sent;

  /// Of [sent], how many have been opened.
  final int opened;

  /// Of [opened], how many got a written reply.
  final int replied;

  /// Whole days until the next locked capsule opens (null when none pending).
  final int? nextDueInDays;

  factory CapsuleStats.fromLetters(List<Letter> letters, DateTime today) {
    final opened = letters.where((letter) => letter.isOpened).toList();
    final replied = opened
        .where((letter) => letter.reply?.trim().isNotEmpty ?? false)
        .length;

    final pending =
        letters
            .where(
              (letter) =>
                  !letter.isOpened &&
                  dateFromUnix(letter.deliverAt).isAfter(today.toMidnight),
            )
            .toList()
          ..sort((a, b) => a.deliverAt.compareTo(b.deliverAt));

    return CapsuleStats(
      sent: letters.length,
      opened: opened.length,
      replied: replied,
      nextDueInDays: pending.isEmpty ? null : daysUntil(pending.first, today),
    );
  }

  bool get hasHistory => sent > 0;
}
