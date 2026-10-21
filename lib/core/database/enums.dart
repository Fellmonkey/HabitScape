import 'package:drift/drift.dart';

/// Stored enums and their drift type converters — pure Dart, no Flutter.
///
/// Anything that renders (icons, colours, Russian labels) lives in
/// `core/theme/enum_visuals.dart`; domain and storage code must not see it.
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

  static TimeOfDay fromString(String value) =>
      TimeOfDay.values.firstWhere((e) => e.name == value);
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

/// Drift type converter between [LogStatus] and its stored string value.
class LogStatusConverter extends TypeConverter<LogStatus, String> {
  const LogStatusConverter();

  @override
  LogStatus fromSql(String fromDb) => LogStatus.fromString(fromDb);

  @override
  String toSql(LogStatus value) => value.name;
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

/// Drift type converter between [DayMood] and its stored string value.
class DayMoodConverter extends TypeConverter<DayMood, String> {
  const DayMoodConverter();

  @override
  DayMood fromSql(String fromDb) => DayMood.fromString(fromDb);

  @override
  String toSql(DayMood value) => value.name;
}

/// How rationally the day's time was used, from 1 (wasted) to 5 (max).
/// Legacy: no longer asked, but preserved on edit so old notes keep data.
enum TimeQuality {
  wasted(1),
  lazy(2),
  normal(3),
  good(4),
  max(5);

  const TimeQuality(this.value);

  /// Stored int value (1–5).
  final int value;

  static TimeQuality? fromValue(int? value) => value == null
      ? null
      : TimeQuality.values.firstWhere(
          (e) => e.value == value,
          orElse: () => TimeQuality.normal,
        );
}
