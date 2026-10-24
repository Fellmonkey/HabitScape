import 'package:flutter/material.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/stats_engine.dart';

/// Week-over-week trend card: how this week compares to the previous one.
class WeekTrendCard extends StatelessWidget {
  const WeekTrendCard({super.key, required this.stats});

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
    final color = progressColor(pctInt);

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
