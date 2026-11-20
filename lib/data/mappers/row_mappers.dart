import '../../core/database/app_database.dart' as rows;
import '../../domain/models/entities.dart';

/// Drift row → clean domain entity. The only place that knows both types.

extension HabitRowMapper on rows.Habit {
  Habit toDomain() => Habit(
    id: id,
    name: name,
    category: category,
    icon: icon,
    frequencyType: frequencyType,
    frequencyValue: frequencyValue,
    timeOfDay: timeOfDay,
    isFocus: isFocus,
    isArchived: isArchived,
    createdAt: createdAt,
  );
}

extension HabitLogRowMapper on rows.HabitLog {
  HabitLog toDomain() => HabitLog(
    id: id,
    habitId: habitId,
    date: date,
    status: status,
    loggedHour: loggedHour,
  );
}

extension DayNoteRowMapper on rows.DayNote {
  DayNote toDomain() => DayNote(
    id: id,
    date: date,
    moment: moment,
    mood: mood,
    timeQuality: timeQuality,
  );
}

extension MonthlyGoalRowMapper on rows.MonthlyGoal {
  MonthlyGoal toDomain() =>
      MonthlyGoal(id: id, month: month, title: title, isDone: isDone);
}

extension LetterRowMapper on rows.Letter {
  Letter toDomain() => Letter(
    id: id,
    createdAt: createdAt,
    deliverAt: deliverAt,
    body: body,
    isOpened: isOpened,
    openedAt: openedAt,
    reaction: reaction,
    reply: reply,
  );
}

extension WeeklyIntentionRowMapper on rows.WeeklyIntention {
  WeeklyIntention toDomain() =>
      WeeklyIntention(id: id, weekStart: weekStart, intention: intention);
}

extension RowListMappers<T> on List<T> {
  List<R> mapToDomain<R>(R Function(T row) mapper) => map(mapper).toList();
}
