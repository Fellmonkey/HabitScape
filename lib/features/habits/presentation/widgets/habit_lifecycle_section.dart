import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/habit_lifecycle_providers.dart';

/// «Жизненный цикл» on a habit's detail screen: age, completion stability and
/// done counts over the habit's whole life — not just the current month.
class HabitLifecycleSection extends ConsumerWidget {
  const HabitLifecycleSection({super.key, required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycleAsync = ref.watch(habitLifecycleDetailProvider(habitId));
    final theme = Theme.of(context);

    return lifecycleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (lifecycle) {
        if (lifecycle == null) return const SizedBox.shrink();
        final pct = lifecycle.stabilityPct.round();
        final color = progressColor(
          pct,
          good: context.palette.sage,
          okay: context.palette.amber,
          bad: context.palette.rose,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Жизненный цикл', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _LifeStat(
                  label: 'Возраст',
                  value: habitAgeLabel(lifecycle.ageDays),
                ),
                const SizedBox(width: 8),
                _LifeStat(
                  label: 'Выполнено',
                  value: '${lifecycle.doneCount} из ${lifecycle.expectedCount}',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Стабильность', style: theme.textTheme.bodyMedium),
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
      },
    );
  }
}

class _LifeStat extends StatelessWidget {
  const _LifeStat({required this.label, required this.value});

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
