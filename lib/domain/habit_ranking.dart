import 'completion.dart';
import 'models/entities.dart';

typedef HabitRank = ({int habitId, String name, int done, int expected});

/// One rule for picking a best or weakest habit from measures already
/// computed by the caller. Returns null when nothing qualifies.
HabitRank? pickBestHabit(
  Iterable<Habit> habits,
  Map<int, Completion> measures, {
  bool Function(Completion measure)? eligible,
}) {
  final accepts = eligible ?? ((m) => m.hasExpectation && m.numerator > 0);
  HabitRank? best;
  for (final habit in habits) {
    final measure = measures[habit.id];
    if (measure == null || !accepts(measure)) continue;
    if (best == null || measure.ratioOrZero > best.done / best.expected) {
      best = (
        habitId: habit.id,
        name: habit.name,
        done: measure.numerator,
        expected: measure.denominator,
      );
    }
  }
  return best;
}

HabitRank? pickWeakestHabit(
  Iterable<Habit> habits,
  Map<int, Completion> measures, {
  bool Function(Completion measure)? eligible,
}) {
  final accepts = eligible ?? ((m) => m.hasExpectation && m.numerator > 0);
  HabitRank? weakest;
  for (final habit in habits) {
    final measure = measures[habit.id];
    if (measure == null || !accepts(measure)) continue;
    if (weakest == null ||
        measure.ratioOrZero < weakest.done / weakest.expected) {
      weakest = (
        habitId: habit.id,
        name: habit.name,
        done: measure.numerator,
        expected: measure.denominator,
      );
    }
  }
  return weakest;
}
