import '../../core/domain/enums.dart';

/// Immutable domain entities. These are the types the rest of the app works
/// with; Drift row classes stay inside `core/database` and are mapped here.
///
/// Hand-written value objects (no freezed dependency): `const`, `final`
/// fields, structural `==`/`hashCode` and `copyWith`.

class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.frequencyType,
    required this.frequencyValue,
    required this.timeOfDay,
    required this.isFocus,
    required this.isArchived,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String category;
  final String icon;
  final String frequencyType;
  final String frequencyValue;
  final String timeOfDay;
  final bool isFocus;
  final bool isArchived;
  final int createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          icon == other.icon &&
          frequencyType == other.frequencyType &&
          frequencyValue == other.frequencyValue &&
          timeOfDay == other.timeOfDay &&
          isFocus == other.isFocus &&
          isArchived == other.isArchived &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    icon,
    frequencyType,
    frequencyValue,
    timeOfDay,
    isFocus,
    isArchived,
    createdAt,
  );

  Habit copyWith({
    int? id,
    String? name,
    String? category,
    String? icon,
    String? frequencyType,
    String? frequencyValue,
    String? timeOfDay,
    bool? isFocus,
    bool? isArchived,
    int? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyValue: frequencyValue ?? this.frequencyValue,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      isFocus: isFocus ?? this.isFocus,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class HabitLog {
  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
    this.loggedHour,
  });

  final int id;
  final int habitId;
  final int date;
  final LogStatus status;
  final int? loggedHour;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLog &&
          id == other.id &&
          habitId == other.habitId &&
          date == other.date &&
          status == other.status &&
          loggedHour == other.loggedHour;

  @override
  int get hashCode => Object.hash(id, habitId, date, status, loggedHour);

  HabitLog copyWith({
    int? id,
    int? habitId,
    int? date,
    LogStatus? status,
    int? loggedHour,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
      loggedHour: loggedHour ?? this.loggedHour,
    );
  }
}

class DayNote {
  const DayNote({
    required this.id,
    required this.date,
    this.moment,
    this.mood,
    this.timeQuality,
  });

  final int id;
  final int date;
  final String? moment;
  final DayMood? mood;
  final int? timeQuality;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayNote &&
          id == other.id &&
          date == other.date &&
          moment == other.moment &&
          mood == other.mood &&
          timeQuality == other.timeQuality;

  @override
  int get hashCode => Object.hash(id, date, moment, mood, timeQuality);

  DayNote copyWith({
    int? id,
    int? date,
    String? moment,
    DayMood? mood,
    int? timeQuality,
  }) {
    return DayNote(
      id: id ?? this.id,
      date: date ?? this.date,
      moment: moment ?? this.moment,
      mood: mood ?? this.mood,
      timeQuality: timeQuality ?? this.timeQuality,
    );
  }
}

class MonthlyGoal {
  const MonthlyGoal({
    required this.id,
    required this.month,
    required this.title,
    required this.isDone,
  });

  final int id;
  final int month;
  final String title;
  final bool isDone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthlyGoal &&
          id == other.id &&
          month == other.month &&
          title == other.title &&
          isDone == other.isDone;

  @override
  int get hashCode => Object.hash(id, month, title, isDone);

  MonthlyGoal copyWith({int? id, int? month, String? title, bool? isDone}) {
    return MonthlyGoal(
      id: id ?? this.id,
      month: month ?? this.month,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}

class Letter {
  const Letter({
    required this.id,
    required this.createdAt,
    required this.deliverAt,
    required this.body,
    required this.isOpened,
    this.openedAt,
    this.reaction,
    this.reply,
  });

  final int id;
  final int createdAt;
  final int deliverAt;
  final String body;
  final bool isOpened;
  final int? openedAt;
  final String? reaction;
  final String? reply;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Letter &&
          id == other.id &&
          createdAt == other.createdAt &&
          deliverAt == other.deliverAt &&
          body == other.body &&
          isOpened == other.isOpened &&
          openedAt == other.openedAt &&
          reaction == other.reaction &&
          reply == other.reply;

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    deliverAt,
    body,
    isOpened,
    openedAt,
    reaction,
    reply,
  );

  Letter copyWith({
    int? id,
    int? createdAt,
    int? deliverAt,
    String? body,
    bool? isOpened,
    int? openedAt,
    String? reaction,
    String? reply,
  }) {
    return Letter(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      deliverAt: deliverAt ?? this.deliverAt,
      body: body ?? this.body,
      isOpened: isOpened ?? this.isOpened,
      openedAt: openedAt ?? this.openedAt,
      reaction: reaction ?? this.reaction,
      reply: reply ?? this.reply,
    );
  }
}

class WeeklyIntention {
  const WeeklyIntention({
    required this.id,
    required this.weekStart,
    this.intention,
  });

  final int id;
  final int weekStart;
  final String? intention;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyIntention &&
          id == other.id &&
          weekStart == other.weekStart &&
          intention == other.intention;

  @override
  int get hashCode => Object.hash(id, weekStart, intention);

  WeeklyIntention copyWith({int? id, int? weekStart, String? intention}) {
    return WeeklyIntention(
      id: id ?? this.id,
      weekStart: weekStart ?? this.weekStart,
      intention: intention ?? this.intention,
    );
  }
}
