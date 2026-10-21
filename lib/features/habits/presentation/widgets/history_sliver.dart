import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../domain/habit_history.dart';
import '../../providers/history_pager_provider.dart';

/// Renders [historyPagerProvider]. The cursor, page fetch, month grouping,
/// exhaustion rule, and flat row order live in the pager; this widget draws.
class HistorySection extends ConsumerWidget {
  const HistorySection({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pager = ref.watch(historyPagerProvider(habitId));

    return pager.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (state) {
        if (state.isEmpty) {
          if (state.isExhausted) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Нет записей',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            );
          }
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final itemCount = state.rows.length + (state.hasMore ? 1 : 0);
        return SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < state.rows.length) {
              return switch (state.rows[index]) {
                HistoryMonthRow(:final month) => MonthHeader(group: month),
                HistoryLogRow(:final log) => LogTile(log: log),
              };
            }
            // Footer visible at the end — ask the pager for the next chunk.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!state.isLoading) {
                ref.read(historyPagerProvider(habitId).notifier).loadMore();
              }
            });
            return const SizedBox(height: 40);
          },
        );
      },
    );
  }
}

class MonthHeader extends StatelessWidget {
  const MonthHeader({required this.group, super.key});

  final HabitHistoryMonth group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = group.doneCount;
    final skip = group.skipCount;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Text(
            '${monthNames[group.month]} ${group.year}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Spacer(),
          if (done > 0)
            LogBadge(
              icon: Icons.check_circle_outline,
              color: AppColors.sageGreen,
              count: done,
            ),
          if (skip > 0) ...[
            const SizedBox(width: 6),
            LogBadge(
              icon: Icons.pause_circle_outline,
              color: AppColors.coolGreyBlue,
              count: skip,
            ),
          ],
        ],
      ),
    );
  }
}

class LogBadge extends StatelessWidget {
  const LogBadge({
    required this.icon,
    required this.color,
    required this.count,
    super.key,
  });

  final IconData icon;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class LogTile extends StatelessWidget {
  const LogTile({required this.log, super.key});

  final HabitLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = dateFromUnix(log.date);
    final status = log.status;

    final icon = status.icon;
    final color = status == LogStatus.pending
        ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
        : status.color;

    final statusLabel = status.localizedName;

    final hourStr = log.loggedHour != null ? '  ${log.loggedHour}:00' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            '${d.day}.${d.month.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Text(
            statusLabel,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
          if (hourStr.isNotEmpty)
            Text(
              hourStr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
        ],
      ),
    );
  }
}
