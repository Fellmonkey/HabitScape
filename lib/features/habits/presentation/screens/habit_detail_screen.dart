import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/calendar_grid.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../shared/widgets/app_sheets.dart';

import '../../domain/habit_engine.dart';
import '../../domain/habit_history.dart';
import '../../domain/scheduling.dart';
import '../../providers/habit_providers.dart';
import '../../providers/history_pager_provider.dart';
import '../widgets/habit_form_sheet.dart';

/// Habit detail screen — stats, heatmap, streak info, time distribution.
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({required this.habitId, super.key});

  final int habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  int _tab = 0;

  int get habitId => widget.habitId;

  @override
  Widget build(BuildContext context) {
    final habitAsync = ref.watch(habitProvider(habitId));
    final theme = Theme.of(context);
    final now = ref.watch(todayDateProvider);

    return habitAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Ошибка: $e')),
      ),
      data: (habit) {
        final metricsAsync = ref.watch(
          habitMetricsProvider((
            habitId: habitId,
            year: now.year,
            month: now.month,
          )),
        );

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    habit.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  titlePadding: const EdgeInsets.only(
                    left: 56,
                    bottom: 16,
                    right: 16,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Редактировать',
                    onPressed: () => _showEditSheet(context, ref, habit),
                  ),
                  if (habit.isFocus)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.warmAmber,
                      ),
                    ),
                  PopupMenuButton<String>(
                    key: K.habitDetailMenu,
                    onSelected: (val) => _handleMenu(context, ref, val, habit),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        key: K.habitDetailSkip,
                        value: 'skip',
                        child: Text('Пропустить сегодня'),
                      ),
                      PopupMenuItem(
                        value: habit.isFocus ? 'unfocus' : 'focus',
                        child: Text(
                          habit.isFocus
                              ? 'Убрать из фокуса'
                              : 'Добавить в фокус',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Архивировать'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Удалить'),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Tabs ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Обзор')),
                      ButtonSegment(value: 1, label: Text('История')),
                      ButtonSegment(value: 2, label: Text('Метрики')),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (s) => setState(() => _tab = s.first),
                  ),
                ),
              ),

              // ── Body ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: 8),

                    // Habit info chip row
                    _HabitInfoRow(habit: habit),
                    const SizedBox(height: 20),

                    if (_tab == 0) ...[
                      metricsAsync.when(
                        loading: () => const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Ошибка метрик: $e'),
                        data: (m) => _MonthStatsSection(
                          metrics: m,
                          year: now.year,
                          month: now.month,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Активность за месяц',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _MonthHeatmap(
                        habitId: habitId,
                        year: now.year,
                        month: now.month,
                      ),
                      const SizedBox(height: 24),

                      metricsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (m) => _TimeDistributionSection(metrics: m),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_tab == 1) ...[
                      Text('История', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                    ],

                    if (_tab == 2) ...[
                      metricsAsync.when(
                        loading: () => const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Ошибка метрик: $e'),
                        data: (m) => _MetricsDetailSection(metrics: m),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),

              if (_tab == 1)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: _HistorySection(habitId: habitId),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Habit habit) {
    AppSheets.show(context, builder: (_) => HabitFormSheet(habit: habit));
  }

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    String action,
    Habit habit,
  ) async {
    final actions = ref.read(habitActionsProvider.notifier);
    final nav = Navigator.of(context);

    switch (action) {
      case 'skip':
        await actions.logToday([habitId], status: LogStatus.skip);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Пропуск засчитан. Ничего не сброшено.'),
            ),
          );
        }
      case 'focus':
        final ok = await actions.setFocus(habitId, isFocus: true);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Максимум 5 фокусных привычек')),
          );
        }
      case 'unfocus':
        await actions.setFocus(habitId, isFocus: false);
      case 'archive':
        await actions.setLifecycle(habitId, HabitLifecycle.archive);
        if (context.mounted) nav.pop();
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Удалить привычку?'),
            content: const Text('Это действие нельзя отменить.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await actions.setLifecycle(habitId, HabitLifecycle.delete);
          if (context.mounted) nav.pop();
        }
    }
  }
}

// ── Metrics detail ───────────────────────────────────────────
class _MetricsDetailSection extends StatelessWidget {
  const _MetricsDetailSection({required this.metrics});

  final HabitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Метрики', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Выполнение: ${metrics.completionPct.toStringAsFixed(1)}%'),
        Text('Выполнено: ${metrics.absoluteCompletions}'),
        Text('Ожидалось: ${metrics.requiredBase}'),
        Text('Пропуски: ${metrics.skipCount}'),
        const SizedBox(height: 8),
        Text('Утро: ${(metrics.morningRatio * 100).round()}%'),
        Text('День: ${(metrics.afternoonRatio * 100).round()}%'),
        Text('Вечер: ${(metrics.eveningRatio * 100).round()}%'),
      ],
    );
  }
}

// ── Habit Info Row ───────────────────────────────────────────

class _HabitInfoRow extends StatelessWidget {
  const _HabitInfoRow({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final icon = HabitIcon.fromString(habit.icon);
    final tod = TimeOfDay.fromString(habit.timeOfDay);

    final freqLabel = frequencyLabel(habit);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _InfoChip(icon: icon.icon, label: icon.label),
        _InfoChip(icon: Icons.repeat, label: freqLabel),
        _InfoChip(icon: Icons.schedule, label: tod.localizedName),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: AppRadius.borderS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ── Month Stats Section ─────────────────────────────────────

class _MonthStatsSection extends StatelessWidget {
  const _MonthStatsSection({
    required this.metrics,
    required this.year,
    required this.month,
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
        _CompletionBar(pct: pct),
        const SizedBox(height: 16),

        // Stats grid
        Row(
          children: [
            _StatCard(
              label: 'Выполнений',
              value: '${metrics.absoluteCompletions}',
            ),
            const SizedBox(width: 8),
            _StatCard(label: 'Пропуски', value: '${metrics.skipCount}'),
          ],
        ),
      ],
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.pct});

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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

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

// ── Month Heatmap ───────────────────────────────────────────

class _MonthHeatmap extends ConsumerWidget {
  const _MonthHeatmap({
    required this.habitId,
    required this.year,
    required this.month,
  });

  final int habitId, year, month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider fetches once per visit and is shared with metrics.
    final logsAsync = ref.watch(
      habitMonthLogsProvider((habitId: habitId, year: year, month: month)),
    );
    final today = ref.watch(todayDateProvider);

    return logsAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox(height: 120),
      data: (logs) =>
          _HeatmapGrid(logs: logs, year: year, month: month, today: today),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.logs,
    required this.year,
    required this.month,
    required this.today,
  });

  final List<HabitLog> logs;
  final int year, month;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grid = CalendarGrid.month(
      month: DateTime.utc(year, month),
      today: today,
    );

    final statusMap = <int, LogStatus>{}; // day → status
    for (final log in logs) {
      final d = dateFromUnix(log.date);
      if (d.year == year && d.month == month) {
        statusMap[d.day] = log.status;
      }
    }

    // Weekday header
    return Column(
      children: [
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Center(
                child: Text(
                  shortWeekdayNames[i + 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        for (final week in grid.weeks)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                for (final cell in week)
                  if (cell == null)
                    const Expanded(child: SizedBox(height: 36))
                  else
                    Expanded(
                      child: _DayCell(
                        day: cell.date.day,
                        status: statusMap[cell.date.day],
                        isToday: cell.isToday,
                        isFuture: cell.isFuture,
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.status,
    required this.isToday,
    required this.isFuture,
  });

  final int day;
  final LogStatus? status;
  final bool isToday, isFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? bgColor;
    Color textColor = theme.colorScheme.onSurface;

    if (isFuture) {
      textColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);
    } else if (status != null) {
      switch (status!) {
        case LogStatus.done:
          bgColor = AppColors.sageGreen.withValues(alpha: 0.35);
        case LogStatus.skip:
          bgColor = AppColors.coolGreyBlue.withValues(alpha: 0.25);
        case LogStatus.pending:
          bgColor = theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.15,
          );
      }
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderS,
        border: isToday
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: theme.textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

// ── Time Distribution ───────────────────────────────────────

class _TimeDistributionSection extends StatelessWidget {
  const _TimeDistributionSection({required this.metrics});

  final HabitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Время отметок', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _TimeBar(
              label: 'Утро',
              ratio: metrics.morningRatio,
              color: AppColors.sageGreen,
            ),
            const SizedBox(width: 8),
            _TimeBar(
              label: 'День',
              ratio: metrics.afternoonRatio,
              color: AppColors.warmAmber,
            ),
            const SizedBox(width: 8),
            _TimeBar(
              label: 'Вечер',
              ratio: metrics.eveningRatio,
              color: AppColors.softLavender,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeBar extends StatelessWidget {
  const _TimeBar({
    required this.label,
    required this.ratio,
    required this.color,
  });

  final String label;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    borderRadius: AppRadius.borderS,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(ratio * 100).round()}%', style: theme.textTheme.bodySmall),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ── History (lazy, loaded in chunks) ─────────────────────────

/// Renders [historyPagerProvider]. The cursor, page fetch, month grouping,
/// exhaustion rule, and flat row order live in the pager; this widget draws.
class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.habitId});

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
                HistoryMonthRow(:final month) => _MonthHeader(group: month),
                HistoryLogRow(:final log) => _LogTile(log: log),
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.group});

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
            _LogBadge(
              icon: Icons.check_circle_outline,
              color: AppColors.sageGreen,
              count: done,
            ),
          if (skip > 0) ...[
            const SizedBox(width: 6),
            _LogBadge(
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

class _LogBadge extends StatelessWidget {
  const _LogBadge({
    required this.icon,
    required this.color,
    required this.count,
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

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

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
