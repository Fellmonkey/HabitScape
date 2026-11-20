import 'package:drift/drift.dart';

import '../../domain/enums.dart';

export '../../domain/enums.dart';

/// Drift type converter between [LogStatus] and its stored string value.
class LogStatusConverter extends TypeConverter<LogStatus, String> {
  const LogStatusConverter();

  @override
  LogStatus fromSql(String fromDb) => LogStatus.fromString(fromDb);

  @override
  String toSql(LogStatus value) => value.name;
}

/// Drift type converter between [DayMood] and its stored string value.
class DayMoodConverter extends TypeConverter<DayMood, String> {
  const DayMoodConverter();

  @override
  DayMood fromSql(String fromDb) => DayMood.fromString(fromDb);

  @override
  String toSql(DayMood value) => value.name;
}
