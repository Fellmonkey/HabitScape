import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/year_summary.dart';
import '../../providers/year_summary_providers.dart';
import '../widgets/year_pixels_grid.dart';

/// «Итоги года»: the trailing year in a single screen — a mood year in
/// pixels plus the anchor numbers. Zero input; a looking-back moment.
class YearSummaryScreen extends ConsumerWidget {
  const YearSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearAsync = ref.watch(yearSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: K.yearSummaryScreen,
      appBar: AppBar(title: const Text('Итоги года')),
      body: yearAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            'Не удалось собрать итоги года',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        data: (year) => _buildBody(context, year),
      ),
    );
  }

  Widget _buildBody(BuildContext context, YearSummary year) {
    final theme = Theme.of(context);

    if (!year.hasData) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Здесь соберётся твой год',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Отмечай привычки и записывай моменты — покажем год в пикселях '
            'и главные цифры.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // ── Year in pixels ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.borderL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCardHeader(
                icon: Icons.calendar_view_month_rounded,
                title: 'Год в пикселях',
              ),
              const SizedBox(height: 12),
              YearPixelsGrid(
                moodByDay: year.moodByDay,
                first: year.windowStart,
                today: year.today,
              ),
              const SizedBox(height: 8),
              const MoodPixelsLegend(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Anchor numbers ──
        Container(
          key: K.yearStatsLines,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.borderL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCardHeader(
                icon: Icons.insights_rounded,
                title: 'Цифры года',
              ),
              const SizedBox(height: 12),
              ..._statLines(context, year),
            ],
          ),
        ),
        if (year.frequencyInsights.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadius.borderL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppCardHeader(
                  icon: Icons.schedule_rounded,
                  title: 'Что выполняется лучше',
                ),
                const SizedBox(height: 2),
                Text(
                  'По типам расписаний: процент выполненных ожидаемых дней.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 10),
                ..._frequencyRows(context, year.frequencyInsights),
                const SizedBox(height: 8),
                Text(
                  'Это наблюдение, а не причина — но может подсказать, '
                  'какое расписание тебе подходит.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _statLines(BuildContext context, YearSummary year) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final good = context.palette.sage;

    final lines = <Widget>[];

    void line(IconData icon, Color color, String text) {
      lines.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
      );
    }

    if (year.completionPct != null) {
      final pct = year.completionPct!.round();
      line(
        Icons.task_alt_rounded,
        progressColor(
          pct,
          good: good,
          okay: context.palette.amber,
          bad: context.palette.rose,
        ),
        '$pct% выполнения за год',
      );
    }
    if (year.moodDays > 0) {
      final green = year.moodCounts[DayMood.good] ?? 0;
      line(Icons.mood_rounded, good, '$green из ${year.moodDays} зелёных дней');
    }
    if (year.momentsCount > 0) {
      line(
        Icons.edit_note_rounded,
        muted,
        '${year.momentsCount} ${pluralDays(year.momentsCount)} с моментом',
      );
    }
    if (year.bestMonth != null) {
      final best = year.bestMonth!;
      final label = best.monthStart.year == year.today.year
          ? monthNamesGenitive[best.monthStart.month]
          : '${monthNamesGenitive[best.monthStart.month]} ${best.monthStart.year}';
      line(
        Icons.calendar_month_rounded,
        context.palette.lavender,
        'Лучший месяц — $label (${best.pct.round()}%)',
      );
    }
    if (year.bestHabit != null) {
      final h = year.bestHabit!;
      line(
        Icons.local_florist_rounded,
        good,
        'Лучше всего — ${h.name}: ${h.done} из ${h.expected}',
      );
    }
    if (year.weakestHabit != null &&
        year.weakestHabit!.habitId != year.bestHabit?.habitId) {
      final w = year.weakestHabit!;
      line(
        Icons.spa_outlined,
        muted,
        'Слабее всего — ${w.name}: ${w.done} из ${w.expected}',
      );
    }
    if (year.goals != null) {
      final done = year.goals!.done == year.goals!.total;
      line(
        Icons.flag_rounded,
        done ? good : muted,
        'Цели: ${year.goals!.done} из ${year.goals!.total}',
      );
    }

    return lines;
  }

  List<Widget> _frequencyRows(BuildContext context, List<FrequencyStat> stats) {
    final theme = Theme.of(context);
    return [
      for (final stat in stats)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  stat.type.localizedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.borderS,
                  child: LinearProgressIndicator(
                    value: (stat.pct / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(
                      progressColor(
                        stat.pct.round(),
                        good: context.palette.sage,
                        okay: context.palette.amber,
                        bad: context.palette.rose,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 96,
                child: Text(
                  '${stat.pct.round()}% · ${stat.done} из ${stat.expected}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
