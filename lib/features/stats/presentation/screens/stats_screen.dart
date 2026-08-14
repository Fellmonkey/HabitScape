import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../domain/stats_engine.dart';
import '../../providers/stats_providers.dart';
import '../widgets/github_heatmap.dart';

/// Statistics screen — an informative dashboard across everything:
/// GitHub-style year heatmap, current-month summary and habit ranking.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsOverviewProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статистика',
                      key: K.statsTitle,
                      style: theme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatFullDate(DateTime.now()),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ...statsAsync.when(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Ошибка: $e')),
                ),
              ],
              data: (stats) => [
                // ── Month summary ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: _MonthSummary(stats: stats),
                  ),
                ),

                // ── Year heatmap ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _HeatmapCard(stats: stats),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Mood counts ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Настроение за месяц',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MoodRow(stats: stats),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Habit ranking ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Привычки за месяц',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                if (stats.monthHabitRanks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Пока нет данных'),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverList.separated(
                      itemCount: stats.monthHabitRanks.length,
                      itemBuilder: (context, i) =>
                          _HabitRankTile(rank: stats.monthHabitRanks[i]),
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Month summary ────────────────────────────────────────────

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.stats});

  final StatsOverview stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final avg = stats.monthAvgPct.round();
    final color = avg >= 80
        ? AppColors.sageGreen
        : avg >= 40
        ? AppColors.warmAmber
        : AppColors.dustyRose;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${monthNames[now.month]} ${now.year}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Среднее выполнение', style: theme.textTheme.bodyMedium),
              Text(
                '$avg%',
                style: theme.textTheme.titleMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.borderS,
            child: LinearProgressIndicator(
              value: avg / 100.0,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MiniStat(label: 'Выполнено', value: '${stats.monthTotalDone}'),
              const SizedBox(width: 8),
              _MiniStat(
                label: 'Ожидалось',
                value: '${stats.monthTotalExpected}',
              ),
              const SizedBox(width: 8),
              _MiniStat(label: 'За год', value: '${stats.yearTotalDone}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          borderRadius: AppRadius.borderM,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Heatmap card ─────────────────────────────────────────────

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.stats});

  final StatsOverview stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Активность за год', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          GithubHeatmap(key: K.statsHeatmap, days: stats.days),
          const SizedBox(height: 4),
          const HeatmapLegend(),
        ],
      ),
    );
  }
}

// ── Mood row ─────────────────────────────────────────────────

class _MoodRow extends StatelessWidget {
  const _MoodRow({required this.stats});

  final StatsOverview stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final good = stats.monthMoods[DayMood.good] ?? 0;
    final ok = stats.monthMoods[DayMood.ok] ?? 0;
    final bad = stats.monthMoods[DayMood.bad] ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Row(
        children: [
          _MoodPill(color: DayMood.good.color, label: '$good 🟢'),
          const SizedBox(width: 8),
          _MoodPill(color: DayMood.ok.color, label: '$ok 🟡'),
          const SizedBox(width: 8),
          _MoodPill(color: DayMood.bad.color, label: '$bad 🔴'),
        ],
      ),
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: AppRadius.borderS,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
      ),
    );
  }
}

// ── Habit rank tile ──────────────────────────────────────────

class _HabitRankTile extends StatelessWidget {
  const _HabitRankTile({required this.rank});

  final HabitRank rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = rank.habit;
    final metrics = rank.metrics;
    final pct = metrics.completionPct.round();
    final color = pct >= 80
        ? AppColors.sageGreen
        : pct >= 40
        ? AppColors.warmAmber
        : AppColors.dustyRose;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderM,
      ),
      child: Row(
        children: [
          if (habit.isFocus)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(
                Icons.star_rounded,
                size: 16,
                color: AppColors.warmAmber,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${metrics.absoluteCompletions}/${metrics.adjustedBase}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    if (metrics.maxStreak > 1) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.local_fire_department_rounded,
                        size: 12,
                        color: AppColors.warmAmber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${metrics.maxStreak}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warmAmber,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$pct%',
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: ClipRRect(
              borderRadius: AppRadius.borderS,
              child: LinearProgressIndicator(
                value: pct / 100.0,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
