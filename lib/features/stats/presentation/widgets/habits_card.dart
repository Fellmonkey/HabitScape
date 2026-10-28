import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/habit_lifecycle.dart';
import '../../providers/habit_lifecycle_providers.dart';

/// «Привычки»: every active habit with its age and completion stability —
/// a compact life-span overview that doubles as a shortcut to habit details.
class HabitsCard extends ConsumerWidget {
  const HabitsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycleAsync = ref.watch(habitLifecycleProvider);
    final theme = Theme.of(context);

    return Container(
      key: K.statsHabits,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: lifecycleAsync.when(
        loading: () => const SizedBox(height: 80),
        error: (_, _) => const SizedBox(height: 80),
        data: (lifecycles) {
          final active = lifecycles.where((l) => !l.isArchived).toList();
          if (active.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCardHeader(
                icon: Icons.local_florist_rounded,
                title: 'Привычки',
              ),
              const SizedBox(height: 10),
              for (final lifecycle in active) _HabitRow(lifecycle: lifecycle),
            ],
          );
        },
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({required this.lifecycle});

  final HabitLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final pct = lifecycle.stabilityPct.round();
    final color = progressColor(
      pct,
      good: context.palette.sage,
      okay: context.palette.amber,
      bad: context.palette.rose,
    );

    return InkWell(
      key: K.statsHabitRow(lifecycle.habit.id),
      borderRadius: AppRadius.borderM,
      onTap: () => context.push('/habit/${lifecycle.habit.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lifecycle.habit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${habitAgeLabel(lifecycle.ageDays)} · $pct%',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
