import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:hintful/hintful.dart';

import '../../../../core/domain/completion.dart';
import '../../../onboarding/app_tours.dart';
import 'month_calendar_grid.dart';
import 'month_goals_card.dart';
import 'month_moment_row.dart';
import 'month_spread_style.dart';
import 'month_summary_section.dart';

export 'month_calendar_grid.dart';
export 'month_moment_row.dart';
export 'month_spread_style.dart';
export 'month_summary_section.dart';

/// Builds the ordered sections of the month spread for one mode.
///
/// [summary] carries the aggregated header stats (completion, mood counts,
/// moments count) computed by the spread provider — the widgets here render,
/// they never re-derive percentages.
List<Widget> buildSpreadSections(
  BuildContext context,
  DateTime today,
  MonthSpreadStyle style, {
  required List<MonthSpreadDay> days,
  required int monthTs,
  required ValueChanged<DateTime> onDayTap,
  required MonthSpreadSummary summary,
}) {
  final theme = Theme.of(context);
  final moments = days.where((d) => d.hasMoment).toList();

  return [
    Padding(
      padding: style.summaryInsets,
      child: MonthSummarySection(summary: summary),
    ),
    if (style.wrapGridInHint)
      HintTarget(
        id: AppHintIds.spreadGrid,
        child: MonthCalendarGrid(
          days: days,
          today: today,
          onDayTap: onDayTap,
          gridKey: style.gridKey,
          debugDayKeys: style.debugDayKeys,
        ),
      )
    else
      MonthCalendarGrid(
        days: days,
        today: today,
        onDayTap: onDayTap,
        gridKey: style.gridKey,
        debugDayKeys: style.debugDayKeys,
      ),
    if (style.includeGoals) MonthGoalsCard(monthTs: monthTs),
    if (moments.isNotEmpty) ...[
      if (style.preMomentsGap != 0) SizedBox(height: style.preMomentsGap),
      Padding(
        padding: style.momentsTitleInsets,
        child: Text(
          'Моменты месяца',
          key: style.momentsKey,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      Padding(
        padding: style.momentsListInsets,
        child: Column(
          children: [
            for (final day in moments)
              MonthMomentRow(day: day, onTap: () => onDayTap(day.date)),
          ],
        ),
      ),
    ],
  ];
}
