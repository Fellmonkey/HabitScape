import '../../../domain/enums.dart';
import '../../../domain/models/entities.dart';
import '../../../domain/scheduling.dart';
import 'habit_templates.dart';

/// Mutable descriptor of a cycle frequency: length, active days, optional
/// per-day labels, and the optional start date. Owned by the form ViewModel.
class CycleConfig {
  const CycleConfig({
    required this.length,
    required this.days,
    required this.labels,
    this.startDate,
  });

  final int length;
  final Set<int> days;
  final Map<int, String> labels;
  final DateTime? startDate;

  CycleConfig copyWith({
    int? length,
    Set<int>? days,
    Map<int, String>? labels,
    DateTime? startDate,
  }) {
    return CycleConfig(
      length: length ?? this.length,
      days: days ?? this.days,
      labels: labels ?? this.labels,
      startDate: startDate ?? this.startDate,
    );
  }
}

/// Immutable snapshot of everything the habit form can edit. Transforming it
/// into a domain [HabitFrequency] is a pure function of this state.
class HabitFormDraft {
  const HabitFormDraft({
    required this.name,
    required this.frequency,
    required this.timeOfDay,
    required this.icon,
    required this.weekdays,
    required this.xValue,
    required this.everyXDays,
    required this.cycle,
    required this.advancedExpanded,
  });

  final String name;
  final FrequencyType frequency;
  final TimeOfDay timeOfDay;
  final HabitIcon icon;

  /// Unmodifiable copy — the ViewModel replaces it on every edit.
  final Set<int> weekdays;
  final int xValue;
  final int everyXDays;
  final CycleConfig cycle;
  final bool advancedExpanded;

  bool get canSave => name.trim().isNotEmpty;

  HabitFormDraft copyWith({
    String? name,
    FrequencyType? frequency,
    TimeOfDay? timeOfDay,
    HabitIcon? icon,
    Set<int>? weekdays,
    int? xValue,
    int? everyXDays,
    CycleConfig? cycle,
    bool? advancedExpanded,
  }) {
    return HabitFormDraft(
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      icon: icon ?? this.icon,
      weekdays: weekdays ?? this.weekdays,
      xValue: xValue ?? this.xValue,
      everyXDays: everyXDays ?? this.everyXDays,
      cycle: cycle ?? this.cycle,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
    );
  }

  HabitFrequency buildFrequency() => switch (frequency) {
    FrequencyType.weekdays => WeekdaysFrequency(weekdays.toList()..sort()),
    FrequencyType.xPerWeek => XPerWeekFrequency(xValue),
    FrequencyType.everyXDays => EveryXDaysFrequency(everyXDays),
    FrequencyType.cycle => CycleFrequency(
      length: cycle.length,
      days: cycle.days.toList()..sort(),
      labels: cycle.labels,
      startDate: CycleFrequency.encodeStartDate(cycle.startDate),
    ),
    _ => const DailyFrequency(),
  };
}

/// Builds the initial draft from an existing habit, or from new-habit
/// defaults. Parsing domain values from persisted strings happens here, not in
/// the widget.
HabitFormDraft initialHabitFormDraft(Habit? habit) {
  final h = habit;
  if (h == null) {
    return const HabitFormDraft(
      name: '',
      frequency: FrequencyType.daily,
      timeOfDay: TimeOfDay.anytime,
      icon: HabitIcon.check,
      weekdays: {1, 2, 3, 4, 5},
      xValue: 3,
      everyXDays: 7,
      cycle: CycleConfig(length: 5, days: {1}, labels: {}),
      advancedExpanded: false,
    );
  }

  final frequency = HabitFrequency.fromHabit(h);
  final parsedX = switch (frequency) {
    XPerWeekFrequency(:final x) => x,
    EveryXDaysFrequency(:final x) => x,
    _ => 1,
  };
  final type = frequency.type;
  final cycle = frequency is CycleFrequency
      ? frequency
      : CycleFrequency(length: 5, days: const [1]);

  return HabitFormDraft(
    name: h.name,
    frequency: type,
    timeOfDay: TimeOfDay.fromString(h.timeOfDay),
    icon: HabitIcon.fromString(h.icon),
    weekdays: frequency is WeekdaysFrequency
        ? frequency.days.toSet()
        : const {1, 2, 3, 4, 5},
    xValue: type == FrequencyType.xPerWeek && parsedX > 1 ? parsedX : 3,
    everyXDays: type == FrequencyType.everyXDays && parsedX > 1 ? parsedX : 7,
    cycle: CycleConfig(
      length: cycle.length,
      days: cycle.days.toSet(),
      labels: Map.from(cycle.labels),
      startDate: CycleFrequency.decodeStartDate(cycle.startDate),
    ),
    advancedExpanded: true,
  );
}

/// Applies a ready-made template to a draft. Kept pure so the ViewModel just
/// replaces its state and the widget never switches over domain types.
HabitFormDraft applyTemplateToDraft(HabitFormDraft draft, HabitTemplate t) {
  final frequency = t.frequency;
  final cycle = draft.cycle;
  return HabitFormDraft(
    name: t.name,
    frequency: frequency.type,
    timeOfDay: t.timeOfDay,
    icon: t.icon,
    weekdays: switch (frequency) {
      WeekdaysFrequency(:final days) => days.toSet(),
      _ => draft.weekdays,
    },
    xValue: switch (frequency) {
      XPerWeekFrequency(:final x) => x < 1 ? 3 : x,
      _ => draft.xValue,
    },
    everyXDays: switch (frequency) {
      EveryXDaysFrequency(:final x) => x < 2 ? 7 : x,
      _ => draft.everyXDays,
    },
    cycle: switch (frequency) {
      CycleFrequency() => cycle.copyWith(
        length: frequency.length,
        days: frequency.days.toSet(),
        labels: Map.from(frequency.labels),
      ),
      _ => cycle,
    },
    advancedExpanded: false,
  );
}
