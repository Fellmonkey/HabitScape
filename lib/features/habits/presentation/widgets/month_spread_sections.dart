import 'package:flutter/material.dart';
import 'package:hintful/hintful.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/domain/completion.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/utils/calendar_grid.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../onboarding/app_tours.dart';
import 'month_goals_card.dart';

/// Layout differences between the live screen and the PNG exporter.
///
/// Both modes render the same section primitives below; the style only picks
/// chrome (keys, hint targets, insets, whether goals appear).
class MonthSpreadStyle {
  const MonthSpreadStyle({
    required this.summaryInsets,
    required this.gridKey,
    required this.debugDayKeys,
    required this.wrapGridInHint,
    required this.includeGoals,
    required this.momentsTitleInsets,
    required this.momentsListInsets,
    required this.momentsKey,
    required this.preMomentsGap,
  });

  final EdgeInsets summaryInsets;
  final Key gridKey;
  final bool debugDayKeys;
  final bool wrapGridInHint;
  final bool includeGoals;
  final EdgeInsets momentsTitleInsets;
  final EdgeInsets momentsListInsets;
  final Key? momentsKey;
  final double preMomentsGap;

  static const live = MonthSpreadStyle(
    summaryInsets: EdgeInsets.fromLTRB(20, 8, 20, 8),
    gridKey: K.monthSpreadGrid,
    debugDayKeys: true,
    wrapGridInHint: true,
    includeGoals: true,
    momentsTitleInsets: EdgeInsets.fromLTRB(20, 8, 20, 4),
    momentsListInsets: EdgeInsets.fromLTRB(20, 0, 20, 24),
    momentsKey: K.monthSpreadMoments,
    preMomentsGap: 0,
  );

  static const capture = MonthSpreadStyle(
    summaryInsets: EdgeInsets.zero,
    gridKey: Key('month_spread_grid_capture'),
    debugDayKeys: false,
    wrapGridInHint: false,
    includeGoals: false,
    momentsTitleInsets: EdgeInsets.zero,
    momentsListInsets: EdgeInsets.zero,
    momentsKey: null,
    preMomentsGap: 8,
  );
}

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

// ── Month summary ─────────────────────────────────────────────

/// Mood chips, completion over the month's elapsed days, and the
/// written-moments counter. Pure presentation: everything numeric arrives
/// precomputed in [MonthSpreadSummary].
class MonthSummarySection extends StatelessWidget {
  const MonthSummarySection({required this.summary, super.key});

  final MonthSpreadSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodCounts = summary.moodCounts;
    final progress = summary.completionPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MonthMoodCount(
              mood: DayMood.good,
              count: moodCounts[DayMood.good]!,
            ),
            const SizedBox(width: 12),
            MonthMoodCount(mood: DayMood.ok, count: moodCounts[DayMood.ok]!),
            const SizedBox(width: 12),
            MonthMoodCount(mood: DayMood.bad, count: moodCounts[DayMood.bad]!),
            const Spacer(),
            Text(
              '${summary.momentsCount} ${pluralMoments(summary.momentsCount)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Выполнено за месяц', style: theme.textTheme.labelSmall),
              const Spacer(),
              Text(
                '${progress.round()}%',
                key: K.monthSpreadProgress,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: progressColor(progress),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.borderS,
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation(progressColor(progress)),
            ),
          ),
        ],
      ],
    );
  }
}

class MonthMoodCount extends StatelessWidget {
  const MonthMoodCount({required this.mood, required this.count, super.key});

  final DayMood mood;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: mood.color.withValues(alpha: 0.14),
        borderRadius: AppRadius.borderM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: mood.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────

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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
        mood?.color.withValues(alpha: 0.3) ??
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
                          color: mood?.color ?? theme.colorScheme.primary,
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
                          ? AppColors.emeraldGlow
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day.done == 0 ? '—' : '${day.done}/${day.expected}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

// ── Day-moment row ─────────────────────────────────────────────

class MonthMomentRow extends StatelessWidget {
  const MonthMomentRow({required this.day, required this.onTap, super.key});

  final MonthSpreadDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = day.mood;

    return InkWell(
      borderRadius: AppRadius.borderS,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    shortWeekdayNames[day.date.weekday],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color:
                    mood?.color ??
                    theme.colorScheme.onSurface.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                day.moment!,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
