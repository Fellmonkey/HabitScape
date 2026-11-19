// Storage-neutral enums shared by domain, data and presentation.
// These describe *what* is stored, never *how* it is rendered or persisted.
// Drift `TypeConverter`s live in `core/database/enums.dart`.

enum FrequencyType {
  daily,
  weekdays,
  xPerWeek,
  everyXDays,
  cycle;

  static FrequencyType fromString(String value) => FrequencyType.values
      .firstWhere((e) => e.name == value, orElse: () => FrequencyType.daily);
}

enum TimeOfDay {
  morning,
  afternoon,
  evening,
  anytime;

  static TimeOfDay fromString(String value) => TimeOfDay.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TimeOfDay.anytime,
  );
}

/// Icon stored on a habit; unknown legacy values fall back to [HabitIcon.check].
enum HabitIcon {
  check,
  fitness,
  book,
  water,
  meditation,
  walk,
  food,
  study,
  work,
  music,
  art,
  sleep,
  finance,
  code,
  photo,
  language,
  cleaning,
  pet,
  run,
  bike,
  pool,
  games,
  movie,
  coffee,
  wakeup,
  screen,
  home,
  science,
  favorite,
  ideas,
  volunteer,
  travel;

  static HabitIcon fromString(String value) => HabitIcon.values.firstWhere(
    (e) => e.name == value,
    orElse: () => HabitIcon.check,
  );
}

enum LogStatus {
  done,
  skip,
  pending;

  /// Parse a stored status string; unknown values fall back to [LogStatus.pending].
  static LogStatus fromString(String value) => LogStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => LogStatus.pending,
  );
}

/// Day mood: 🟢 good / 🟡 ok / 🔴 bad.
enum DayMood {
  good,
  ok,
  bad;

  static DayMood fromString(String value) => DayMood.values.firstWhere(
    (e) => e.name == value,
    orElse: () => DayMood.good,
  );
}
