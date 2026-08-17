import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ads/ads_service.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../domain/stats_engine.dart';
import '../../providers/stats_providers.dart';
import '../widgets/github_heatmap.dart';

/// Statistics screen — an informative dashboard across everything.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsOverviewProvider);
    final theme = Theme.of(context);
    final ads = ref.watch(adsServiceProvider); // banner hides without ad stack

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
                // ── Week trend ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: _WeekTrendCard(stats: stats),
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

                // ── Mood ↔ completion ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Настроение и выполнение',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MoodCorrelationCard(corr: stats.moodCorrelation),
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

                // ── Weekly rhythm ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Ритм недели',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _RhythmCard(rhythm: stats.rhythm),
                  ),
                ),
                if (ads.isAvailable)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                      child: KeyedSubtree(
                        key: K.statsInlineAd,
                        child: ads.buildInlineAd(context),
                      ),
                    ),
                  )
                else
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week trend ───────────────────────────────────────────────

class _WeekTrendCard extends StatelessWidget {
  const _WeekTrendCard({required this.stats});

  final StatsOverview stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trend = stats.weekTrend;
    final delta = trend.delta;
    final rising = delta > 0.5;
    final falling = delta < -0.5;
    final deltaColor = rising
        ? AppColors.sageGreen
        : falling
        ? AppColors.dustyRose
        : theme.colorScheme.onSurface.withValues(alpha: 0.5);
    final deltaIcon = rising
        ? Icons.trending_up_rounded
        : falling
        ? Icons.trending_down_rounded
        : Icons.trending_flat_rounded;

    return Container(
      key: K.statsWeekTrend,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Эта неделя', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (!trend.hasData)
            Text(
              'Отмечай привычки — здесь появится сравнение с прошлой неделей.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            )
          else ...[
            _WeekRow(label: 'Эта неделя', pct: trend.thisWeekPct),
            const SizedBox(height: 10),
            _WeekRow(label: 'Прошлая', pct: trend.lastWeekPct),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(deltaIcon, size: 18, color: deltaColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    delta.abs() < 0.5
                        ? 'Так же, как на прошлой неделе'
                        : 'На ${delta.abs().round()}% ${rising ? 'лучше' : 'хуже'}, чем на прошлой неделе',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: deltaColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _MiniStat(label: 'Выполнено', value: '${trend.thisWeekDone}'),
                const SizedBox(width: 8),
                _MiniStat(
                  label: 'Ожидалось',
                  value: '${trend.thisWeekExpected}',
                ),
                const SizedBox(width: 8),
                _MiniStat(label: 'За год', value: '${stats.yearTotalDone}'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.label, required this.pct});

  final String label;
  final double pct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctInt = pct.round();
    final color = pctInt >= 80
        ? AppColors.sageGreen
        : pctInt >= 40
        ? AppColors.warmAmber
        : AppColors.dustyRose;

    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.borderS,
            child: LinearProgressIndicator(
              value: pct / 100.0,
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            '$pctInt%',
            textAlign: TextAlign.end,
            style: theme.textTheme.titleSmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

// ── Mood ↔ completion ────────────────────────────────────────

class _MoodCorrelationCard extends StatelessWidget {
  const _MoodCorrelationCard({required this.corr});

  final MoodCorrelation corr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: K.statsCorrelation,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: !corr.hasData
          ? Text(
              'Заполняй «Момент дня» и отмечай привычки — покажем, как настроение связано с выполнением.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CorrRow(
                  label: 'В дни, когда всё выполнено',
                  value: corr.goodShareOnFull != null
                      ? '🟢 ${corr.goodShareOnFull!.round()}%'
                      : 'пока мало таких дней',
                ),
                const SizedBox(height: 10),
                _CorrRow(
                  label: 'В дни без отметок',
                  value: corr.badShareOnEmpty != null
                      ? '🔴 ${corr.badShareOnEmpty!.round()}%'
                      : 'пока мало таких дней',
                ),
              ],
            ),
    );
  }
}

class _CorrRow extends StatelessWidget {
  const _CorrRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        const SizedBox(width: 8),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Weekly rhythm ────────────────────────────────────────────

class _RhythmCard extends StatelessWidget {
  const _RhythmCard({required this.rhythm});

  final RhythmStats rhythm;

  static const _timeLabels = {
    'morning': 'утром',
    'day': 'днём',
    'evening': 'вечером',
    'night': 'ночью',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = rhythm.bestWeekday;
    final worst = rhythm.worstWeekday;
    final timeBucket = rhythm.timeBucket;

    if (best == null && timeBucket == null) {
      return Container(
        key: K.statsRhythm,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderL,
        ),
        child: Text(
          'Пока мало данных — веди привычки несколько дней.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return Container(
      key: K.statsRhythm,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (best != null && worst != null) ...[
            _RhythmRow(
              icon: Icons.thumb_up_alt_rounded,
              color: AppColors.sageGreen,
              text: 'Лучший день: ${weekdayNames[best]} — ${_pctOf(best)}%',
            ),
            _RhythmRow(
              icon: Icons.thumb_down_alt_rounded,
              color: AppColors.dustyRose,
              text: 'Худший день: ${weekdayNames[worst]} — ${_pctOf(worst)}%',
            ),
          ],
          if (timeBucket != null)
            _RhythmRow(
              icon: Icons.schedule_rounded,
              color: AppColors.warmAmber,
              text:
                  'Пик активности: ${_timeLabels[timeBucket]} — ${rhythm.timeShare.round()}%',
            ),
        ],
      ),
    );
  }

  int _pctOf(int weekday) => (rhythm.weekdays[weekday - 1].ratio * 100).round();
}

class _RhythmRow extends StatelessWidget {
  const _RhythmRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
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
