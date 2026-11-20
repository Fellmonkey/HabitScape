import 'package:flutter/material.dart';

import '../../../../core/theme/motion_tokens.dart';
import '../../../../domain/models/entities.dart';
import '../../domain/today_board.dart';

/// One animated row of the Greenhouse board: a group header or a habit card.
/// The id is the diff key between the current and the next set of rows.
sealed class BoardEntry {
  const BoardEntry();

  String get id;
}

final class GroupHeaderEntry extends BoardEntry {
  const GroupHeaderEntry(this.group);

  final TodayGroup group;

  @override
  String get id => 'g:${group.kind.name}';
}

final class HabitEntry extends BoardEntry {
  const HabitEntry(this.habit, this.log);

  final Habit habit;
  final HabitLog? log;

  @override
  String get id => 'h:${habit.id}';
}

/// Flattens the board into animated-list rows: one header per group, then one
/// card per habit. Extracted here so the screen never does index math.
List<BoardEntry> buildBoardEntries(
  List<TodayGroup> groups,
  Map<int, HabitLog> logByHabit,
) {
  final out = <BoardEntry>[];
  for (final group in groups) {
    if (group.habits.isEmpty) continue;
    out.add(GroupHeaderEntry(group));
    for (final habit in group.habits) {
      out.add(HabitEntry(habit, logByHabit[habit.id]));
    }
  }
  return out;
}

/// Wraps one row in the insert/remove motion. Reduced motion renders the row
/// plainly. The screen supplies the actual header/card builders.
Widget boardEntryRow(
  BuildContext context,
  BoardEntry entry,
  Animation<double> animation, {
  required Widget Function(TodayGroup group) headerBuilder,
  required Widget Function(Habit habit, HabitLog? log) cardBuilder,
  bool removing = false,
}) {
  final child = switch (entry) {
    GroupHeaderEntry(:final group) => headerBuilder(group),
    HabitEntry(:final habit, :final log) => cardBuilder(habit, log),
  };
  if (AppMotion.mayDisable(context)) return child;

  final curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.easeOutStrong,
  );
  return SizeTransition(
    sizeFactor: animation,
    alignment: Alignment.topCenter,
    child: FadeTransition(
      opacity: curved,
      child: removing
          ? child
          : SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.09),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.0).animate(curved),
                child: child,
              ),
            ),
    ),
  );
}
