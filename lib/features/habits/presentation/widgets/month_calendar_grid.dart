import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:hintful/hintful.dart';

import '../../../../core/domain/completion.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/utils/calendar_grid.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../onboarding/app_tours.dart';

/// The month grid: weekday header plus one cell per day, mood-tinted,
/// with habit progress and a moment dot. One module owns the cell geometry
/// and the today spotlight.
class MonthCalendarGrid extends StatelessWidget {
  const MonthCalendarGrid({
    required this.days,
    required this.today,
    required this.onDayTap,
    this.gridKey = K.monthSpreadGrid,
    this.debugDayKeys = true,
    super.key,
  });

  final List<MonthSpreadDay> days;
  final DateTime today;
  final ValueChanged<DateTime> onDayTap;

  /// Grid container key; the PNG capture passes a distinct one to avoid
  /// two widgets sharing `K.monthSpreadGrid`.
  final Key gridKey;

  /// Whether day cells carry `K.monthSpreadDay(n)` test keys (disabled in
  /// the offscreen capture — duplicate local keys would crash the tree).
  final bool debugDayKeys;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayDay = today.toMidnight;
    final grid = CalendarGrid.month(month: days.first.date, today: todayDay);
    final dayByDate = {for (final day in days) day.date: day};

    final header = Row(
      children: [
        for (final w in shortWeekdayNames.skip(1))
          Expanded(
            child: Center(
              child: Text(
                w,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
      ],
    );

    final weeks = <Widget>[
      for (final week in grid.weeks)
        Row(
          children: [
            for (final cell in week)
              Expanded(
                child: cell == null
                    ? const SizedBox.shrink()
                    : _wrapDayCell(
                        context,
                        cell: dayByDate[cell.date]!,
                        isToday: cell.isToday,
                        isFuture: cell.isFuture,
                      ),
              ),
          ],
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        key: gridKey,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderL,
        ),
        child: Column(children: [header, const SizedBox(height: 6), ...weeks]),
      ),
    );
  }

  /// Today's cell is the onboarding target — wrap it in a spotlight.
  Widget _wrapDayCell(
    BuildContext context, {
    required MonthSpreadDay cell,
    required bool isToday,
    required bool isFuture,
  }) {
    final cellWidget = MonthDayCell(
      day: cell,
      isToday: isToday,
      isFuture: isFuture,
      onTap: onDayTap,
      dayKey: debugDayKeys ? K.monthSpreadDay(cell.date.day) : null,
    );
    if (!isToday) return cellWidget;
    return HintTarget(id: AppHintIds.spreadDay, child: cellWidget);
  }
}

/// A single day cell: mood-tinted background, habit progress, a dot when a
/// day moment was written, today highlighted with a ring. Future days show
/// the neutral marker instead of an empty progress bar, so a day that hasn't
/// happened yet never reads as missed.
class MonthDayCell extends StatelessWidget {
  const MonthDayCell({
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
    this.dayKey,
    super.key,
  });

  final MonthSpreadDay day;
  final bool isToday;
  final bool isFuture;
  final ValueChanged<DateTime> onTap;

  /// Test key (`K.monthSpreadDay(n)`); null in the offscreen capture copy.
  final Key? dayKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = day.mood;
    final bg =
        mood?.color(context).withValues(alpha: 0.3) ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final hasHabits = day.expected > 0 && !isFuture;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        key: dayKey,
        borderRadius: AppRadius.borderS,
        onTap: () => onTap(day.date),
        child: AnimatedContainer(
          duration: AppMotion.base,
          height: 62,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.borderS,
            border: isToday
                ? Border.all(color: theme.colorScheme.primary, width: 1.6)
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${day.date.day}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (day.hasMoment)
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color:
                              mood?.color(context) ?? theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (hasHabits) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: LinearProgressIndicator(
                    value: day.ratio,
                    minHeight: 4,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                    valueColor: AlwaysStoppedAnimation(
                      day.ratio >= 1.0
                          ? context.palette.emerald
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day.done == 0 ? '—' : '${day.done}/${day.expected}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ] else
                Text(
                  '·',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
