import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/year_summary.dart';
import '../../providers/intentions_providers.dart';

/// «Намерения недель»: the archive of the written weekly intentions with the
/// completion of the week that followed them — the closest thing the app has
/// to "did my intention come true".
class IntentionsCard extends ConsumerWidget {
  const IntentionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intentionsAsync = ref.watch(intentionsProvider);
    final today = ref.watch(todayDateProvider);
    final theme = Theme.of(context);

    return Container(
      key: K.statsIntentions,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: intentionsAsync.when(
        loading: () => const SizedBox(height: 80),
        error: (_, _) => const SizedBox(height: 80),
        data: (intentions) {
          if (intentions.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppCardHeader(
                  icon: Icons.trending_up_rounded,
                  title: 'Намерения недель',
                ),
                const SizedBox(height: 10),
                Text(
                  'Отвечай на итог недели — намерения появятся здесь.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCardHeader(
                icon: Icons.trending_up_rounded,
                title: 'Намерения недель',
              ),
              const SizedBox(height: 12),
              for (final record in intentions.take(4)) ...[
                _IntentionRow(record: record, today: today),
                const SizedBox(height: 4),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _IntentionRow extends StatelessWidget {
  const _IntentionRow({required this.record, required this.today});

  final WeekIntentionRecord record;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              formatShortDate(record.weekStart, today: today),
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '«${record.intention}»',
                  style: theme.textTheme.bodyMedium,
                ),
                if (record.followingWeekPct != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Следующая неделя: ${record.followingWeekPct!.round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
