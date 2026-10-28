import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/habit_lifecycle.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../providers/habit_lifecycle_providers.dart';

/// «Архив»: retired habits with their life span and overall completion — the
/// only place archived habits' numbers survive (the heatmap and year summary
/// only cover active habits). Hidden entirely while loading; shows a header
/// + hint when there is nothing archived yet.
class ArchiveCard extends ConsumerWidget {
  const ArchiveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifecycleAsync = ref.watch(habitLifecycleProvider);
    final theme = Theme.of(context);

    return lifecycleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (lifecycles) {
        final archived = lifecycles.where((l) => l.isArchived).toList();

        return Container(
          key: K.statsArchive,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.borderL,
          ),
          child: archived.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppCardHeader(
                      icon: Icons.archive_outlined,
                      title: 'Архив',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Архив пуст — здесь появятся привычки, которые ты '
                      'завершишь.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppCardHeader(
                      icon: Icons.archive_outlined,
                      title: 'Архив',
                    ),
                    const SizedBox(height: 10),
                    for (final lifecycle in archived)
                      _ArchivedRow(lifecycle: lifecycle),
                  ],
                ),
        );
      },
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({required this.lifecycle});

  final HabitLifecycle lifecycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final pct = lifecycle.stabilityPct.round();

    return InkWell(
      borderRadius: AppRadius.borderM,
      onTap: () => context.push('/archive'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    'жила ${habitAgeLabel(lifecycle.ageDays)} · $pct% · '
                    '${lifecycle.doneCount} выполнений',
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
