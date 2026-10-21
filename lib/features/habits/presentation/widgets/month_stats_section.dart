import 'package:flutter/material.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../domain/habit_engine.dart';

/// The current month's headline stats for one habit: completion progress,
/// done-count and skipped-count cards.
class MonthStatsSection extends StatelessWidget {
  const MonthStatsSection({
    required this.metrics,
    required this.year,
    required this.month,
    super.key,
  });

  final HabitMetrics metrics;
  final int year, month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = metrics.completionPct.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${monthNames[month]} $year', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),

        // Completion progress bar
        CompletionBar(pct: pct),
        const SizedBox(height: 16),

        // Stats grid
        Row(
          children: [
            StatCard(
              label: 'Выполнений',
              value: '${metrics.absoluteCompletions}',
            ),
            const SizedBox(width: 8),
            StatCard(label: 'Пропуски', value: '${metrics.skipCount}'),
          ],
        ),
      ],
    );
  }
}

class CompletionBar extends StatelessWidget {
  const CompletionBar({required this.pct, super.key});

  final int pct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = progressColor(pct);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Выполнение', style: theme.textTheme.bodyMedium),
            Text(
              '$pct%',
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.borderS,
          child: LinearProgressIndicator(
            value: pct / 100.0,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, super.key});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
