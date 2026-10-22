import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hintful/hintful.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/utils/calendar_grid.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../onboarding/app_tours.dart';
import '../../../../core/domain/completion.dart';
import 'month_goals_card.dart';

/// The month spread composition: summary, calendar, goals, and moments.
///
/// The screen and the PNG exporter render the same sections; [capture] only
/// turns off interaction, onboarding targets, test keys, and the goals card.
class MonthSpreadView extends ConsumerWidget {
  const MonthSpreadView({
    required this.days,
    required this.monthTs,
    required this.onDayTap,
    this.capture = false,
    super.key,
  });

  final List<MonthSpreadDay> days;
  final int monthTs;
  final ValueChanged<DateTime> onDayTap;
  final bool capture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayDateProvider);
    final sections = _sections(context, today);

    if (capture) {
      final theme = Theme.of(context);
      return Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            for (final section in sections) section,
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        for (final section in sections) SliverToBoxAdapter(child: section),
      ],
    );
  }

  List<Widget> _sections(BuildContext context, DateTime today) {
    final theme = Theme.of(context);
    final moments = days.where((d) => d.hasMoment).toList();

    return [
      Padding(
        padding: capture
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: _MonthSummary(days: days, today: today),
      ),
      if (capture) ...[
        const SizedBox(height: 12),
        _CalendarGrid(
          days: days,
          today: today,
          onDayTap: (_) {},
          gridKey: const Key('month_spread_grid_capture'),
          debugDayKeys: false,
        ),
      ] else
        HintTarget(
          id: AppHintIds.spreadGrid,
          child: _CalendarGrid(days: days, today: today, onDayTap: onDayTap),
        ),
      if (!capture) MonthGoalsCard(monthTs: monthTs),
      if (moments.isNotEmpty) ...[
        if (capture) const SizedBox(height: 8),
        Padding(
          padding: capture
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            'Моменты месяца',
            key: capture ? null : K.monthSpreadMoments,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: capture
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            children: [
              for (final day in moments)
                _MomentRow(day: day, onTap: () => onDayTap(day.date)),
            ],
          ),
        ),
      ],
    ];
  }
}

// ── Month summary ─────────────────────────────────────────────

/// Mood chips, completion over the month's elapsed days, and the
/// written-moments counter.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.days, required this.today});

  final List<MonthSpreadDay> days;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodCounts = _moodCountsOf(days);
    final moments = days.where((d) => d.hasMoment).length;
    final progress = monthCompletionPct(days: days, today: today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _MoodCount(mood: DayMood.good, count: moodCounts[DayMood.good]!),
            const SizedBox(width: 12),
            _MoodCount(mood: DayMood.ok, count: moodCounts[DayMood.ok]!),
            const SizedBox(width: 12),
            _MoodCount(mood: DayMood.bad, count: moodCounts[DayMood.bad]!),
            const Spacer(),
            Text(
              '$moments ${pluralMoments(moments)}',
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

Map<DayMood, int> _moodCountsOf(List<MonthSpreadDay> days) {
  final counts = <DayMood, int>{for (final m in DayMood.values) m: 0};
  for (final d in days) {
    final mood = d.mood;
    if (mood != null) counts[mood] = counts[mood]! + 1;
  }
  return counts;
}

class _MoodCount extends StatelessWidget {
  const _MoodCount({required this.mood, required this.count});

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

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.today,
    required this.onDayTap,
    this.gridKey = K.monthSpreadGrid,
    this.debugDayKeys = true,
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
    final cellWidget = _DayCell(
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
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
    this.dayKey,
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

class _MomentRow extends StatelessWidget {
  const _MomentRow({required this.day, required this.onTap});

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
