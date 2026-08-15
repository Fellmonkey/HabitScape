import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../stats/domain/stats_engine.dart';
import '../../providers/habit_providers.dart';
import '../widgets/day_moment_sheet.dart';
import '../widgets/month_goals_card.dart';

/// «Разворот месяца» — the main history screen: a calendar week-grid where
/// each day cell shows mood colour + habit marks + a «Момент дня» dot, with
/// the month's goals and the chronological «one line about the day» feed.
class MonthSpreadScreen extends ConsumerStatefulWidget {
  const MonthSpreadScreen({super.key});

  @override
  ConsumerState<MonthSpreadScreen> createState() => _MonthSpreadScreenState();
}

class _MonthSpreadScreenState extends ConsumerState<MonthSpreadScreen> {
  late DateTime _month; // first-of-month of the displayed month

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime.utc(now.year, now.month, 1);
  }

  int get _monthTs => _month.unixSeconds;

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime.utc(_month.year, _month.month + delta, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() => _month = DateTime.utc(now.year, now.month, 1));
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysAsync = ref.watch(monthSpreadProvider(_monthTs));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: K.monthSpreadPrev,
              tooltip: 'Предыдущий месяц',
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              '${monthNames[_month.month]} ${_month.year}',
              key: K.monthSpreadTitle,
              style: theme.textTheme.titleLarge,
            ),
            IconButton(
              key: K.monthSpreadNext,
              tooltip: 'Следующий месяц',
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!_isCurrentMonth)
            TextButton(
              key: K.monthSpreadToday,
              onPressed: _goToToday,
              child: const Text('Сегодня'),
            ),
        ],
      ),
      body: daysAsync.when(
        // No infinite spinner — a hidden body keeps pumpAndSettle happy and
        // avoids a layout flash while the drift streams warm up.
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (days) => _buildBody(context, theme, days),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    List<MonthSpreadDay> days,
  ) {
    final moodCounts = <DayMood, int>{for (final m in DayMood.values) m: 0};
    for (final d in days) {
      final mood = d.mood;
      if (mood != null) moodCounts[mood] = moodCounts[mood]! + 1;
    }

    final moments = days.where((d) => d.hasMoment).toList();
    final monthTs = _monthTs;

    return CustomScrollView(
      slivers: [
        // ── Summary strip: 🟢/🟡/🔴 ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              children: [
                _MoodCount(
                  mood: DayMood.good,
                  count: moodCounts[DayMood.good]!,
                ),
                const SizedBox(width: 12),
                _MoodCount(mood: DayMood.ok, count: moodCounts[DayMood.ok]!),
                const SizedBox(width: 12),
                _MoodCount(mood: DayMood.bad, count: moodCounts[DayMood.bad]!),
                const Spacer(),
                Text(
                  '${moments.length} ${_pluralMoments(moments.length)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Calendar week grid ──
        SliverToBoxAdapter(
          child: _CalendarGrid(days: days, onDayTap: _openDay),
        ),

        // ── Month goals ──
        SliverToBoxAdapter(child: MonthGoalsCard(monthTs: monthTs)),

        // ── «Момент дня» feed (хронологическая лента) ──
        if (moments.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'Моменты месяца',
                key: K.monthSpreadMoments,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverList.builder(
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final day = moments[index];
              return _MomentRow(day: day, onTap: () => _openDay(day.date));
            },
          ),
        ),
      ],
    );
  }

  void _openDay(DateTime date) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DayMomentSheet(dateTimestamp: date.unixSeconds),
    );
    // The sheet may have edited the day — refresh the spread data.
    if (mounted) ref.invalidate(monthSpreadProvider(_monthTs));
  }

  String _pluralMoments(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'момент';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'момента';
    }
    return 'моментов';
  }
}

// ── Mood summary chip ─────────────────────────────────────────

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
  const _CalendarGrid({required this.days, required this.onDayTap});

  final List<MonthSpreadDay> days;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().toMidnight;
    final first = days.first.date;
    final firstWeekday = first.weekday; // 1 = Пн … 7 = Вс
    // Leading blanks so day 1 lands on its weekday column.
    final cells = <MonthSpreadDay?>[
      for (var i = 1; i < firstWeekday; i++) null,
      ...days,
    ];

    // Weekday header row (Пн … Вс).
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

    final weeks = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(i, (i + 7).clamp(0, cells.length));
      weeks.add(
        Row(
          children: [
            for (var c = 0; c < 7; c++)
              Expanded(
                child: c < week.length && week[c] != null
                    ? _DayCell(
                        day: week[c]!,
                        isToday: week[c]!.date == today,
                        onTap: onDayTap,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        key: K.monthSpreadGrid,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderL,
        ),
        child: Column(children: [header, const SizedBox(height: 6), ...weeks]),
      ),
    );
  }
}

/// A single day cell: mood-tinted background, habit progress line,\n/// a dot when a «Момент дня» was written, today highlighted with a ring.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.onTap,
  });

  final MonthSpreadDay day;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = day.mood;
    final bg =
        mood?.color.withValues(alpha: 0.22) ??
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35);
    final hasHabits = day.expected > 0;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        key: K.monthSpreadDay(day.date.day),
        borderRadius: AppRadius.borderS,
        onTap: () => onTap(day.date),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  if (day.hasMoment)
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 10,
                      color: mood?.color ?? theme.colorScheme.primary,
                    ),
                ],
              ),
              const Spacer(),
              if (hasHabits) ...[
                // Tiny completion bar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: LinearProgressIndicator(
                    value: day.ratio,
                    minHeight: 3,
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
                    fontSize: 8,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
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

// ── «Момент дня» row ──────────────────────────────────────────

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
