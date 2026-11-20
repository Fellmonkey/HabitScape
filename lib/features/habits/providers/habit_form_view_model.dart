import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/enums.dart';
import '../../../domain/models/entities.dart';
import '../domain/habit_form_draft.dart';
import '../domain/habit_templates.dart';

/// ViewModel for the create/edit sheet: owns the whole editable draft and
/// exposes commands. The sheet renders the snapshot and dispatches events.
final habitFormViewModelProvider = NotifierProvider.family<
  HabitFormViewModel,
  HabitFormDraft,
  Habit?
>(HabitFormViewModel.new);

class HabitFormViewModel extends Notifier<HabitFormDraft> {
  HabitFormViewModel(this.habit);

  final Habit? habit;

  @override
  HabitFormDraft build() => initialHabitFormDraft(habit);

  void setName(String name) =>
      state = state.copyWith(name: name);

  void setFrequency(FrequencyType frequency) =>
      state = state.copyWith(frequency: frequency);

  void setTimeOfDay(TimeOfDay timeOfDay) =>
      state = state.copyWith(timeOfDay: timeOfDay);

  void setIcon(HabitIcon icon) => state = state.copyWith(icon: icon);

  void setWeekdays(Iterable<int> days) =>
      state = state.copyWith(weekdays: days.toSet());

  void setXValue(int value) => state = state.copyWith(xValue: value);

  void setEveryXDays(int value) => state = state.copyWith(everyXDays: value);

  void setCycle(CycleConfig cycle) => state = state.copyWith(cycle: cycle);

  void setAdvancedExpanded(bool expanded) =>
      state = state.copyWith(advancedExpanded: expanded);

  void applyTemplate(HabitTemplate template) =>
      state = applyTemplateToDraft(state, template);
}
