import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';

import '../../domain/habit_engine.dart';
import '../../domain/scheduling.dart';
import '../../providers/habit_providers.dart';
import '../widgets/habit_form_sheet.dart';

/// Habit detail screen — shows stats, heatmap, streak info, time distribution.
class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({required this.habitId, super.key});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitAsync = ref.watch(habitProvider(habitId));
    final theme = Theme.of(context);
    final now = DateTime.now();

    return habitAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Ошибка: $e')),
      ),
      data: (habit) {
        final metricsAsync = ref.watch(habitMetricsProvider((
          habitId: habitId,
          year: now.year,
          month: now.month,
        )));

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
                  titlePadding:
                      const EdgeInsets.only(left: 56, bottom: 16, right: 16),
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
                    onSelected: (val) =>
                        _handleMenu(context, ref, val, habit),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: habit.isFocus ? 'unfocus' : 'focus',
                        child: Text(habit.isFocus
                            ? 'Убрать из фокуса'
                            : 'Добавить в фокус'),
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

              // ── Body ──
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: 8),

                    // Habit info chip row
                    _HabitInfoRow(habit: habit),
                    const SizedBox(height: 20),

                    // Current month stats
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

                    // Heatmap calendar
                    Text('Активность за месяц',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _MonthHeatmap(
                      habitId: habitId,
                      year: now.year,
                      month: now.month,
                    ),
                    const SizedBox(height: 24),

                    // Time-of-day distribution
                    metricsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (m) => _TimeDistributionSection(metrics: m),
                    ),
                    const SizedBox(height: 24),

                    // All-time logs history
                    Text('История', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _AllLogsSection(habitId: habitId),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, Habit habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitFormSheet(habit: habit),
    );
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
      case 'focus':
        final ok = await actions.toggleFocus(habitId, isFocus: true);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Максимум 5 фокусных привычек')),
          );
        }
      case 'unfocus':
        await actions.toggleFocus(habitId, isFocus: false);
      case 'archive':
        await actions.archiveHabit(habitId);
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
          await actions.deleteHabit(habitId);
          if (context.mounted) nav.pop();
        }
    }
  }
}

// ── Habit Info Row ───────────────────────────────────────────

class _HabitInfoRow extends StatelessWidget {
  const _HabitInfoRow({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context) {
    final archetype = SeedArchetype.fromString(habit.seedArchetype);
    final tod = TimeOfDay.fromString(habit.timeOfDay);

    final freqLabel = frequencyLabel(habit);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _InfoChip(icon: archetype.icon, label: archetype.displayName),
        _InfoChip(icon: Icons.repeat, label: freqLabel),
        _InfoChip(icon: Icons.schedule, label: tod.localizedName),
        if (habit.category.isNotEmpty)
          _InfoChip(icon: Icons.label_outline, label: habit.category),
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

  static const _months = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = metrics.completionPct.round();
    final typeLabel = switch (metrics.objectType) {
      GardenObjectType.tree => 'Дерево',
      GardenObjectType.bush => 'Куст',
      GardenObjectType.grass => 'Трава',
      GardenObjectType.moss => 'Мох',
      GardenObjectType.sleepingBulb => 'Спящая луковица',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${_months[month]} $year', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),

        // Completion progress bar
        _CompletionBar(pct: pct),
        const SizedBox(height: 16),

        // Stats grid
        Row(
          children: [
            _StatCard(label: 'Выполнений', value: '${metrics.absoluteCompletions}'),
            const SizedBox(width: 8),
            _StatCard(label: 'Макс. серия', value: '${metrics.maxStreak}'),
            const SizedBox(width: 8),
            _StatCard(label: 'Пропуски', value: '${metrics.skipCount}'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatCard(label: 'Срывы', value: '${metrics.failCount}'),
            const SizedBox(width: 8),
            _StatCard(label: 'Растение', value: typeLabel),
            const SizedBox(width: 8),
            _StatCard(
              label: 'База',
              value: '${metrics.absoluteCompletions}/${metrics.adjustedBase}',
            ),
          ],
        ),

        // Short-perfect badge
        if (metrics.isShortPerfect) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x20FFD700),
              borderRadius: AppRadius.borderM,
              border: Border.all(color: const Color(0x40FFD700)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Аура идеального старта',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final color = pct >= 80
        ? AppColors.sageGreen
        : pct >= 40
            ? AppColors.warmAmber
            : AppColors.dustyRose;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Выполнение', style: theme.textTheme.bodyMedium),
            Text('$pct%',
                style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.borderS,
          child: LinearProgressIndicator(
            value: pct / 100.0,
            minHeight: 8,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: AppRadius.borderM,
        ),
        child: Column(
          children: [
            Text(value,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center),
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
    final dao = ref.watch(habitLogsDaoProvider);
    final monthStart = DateTime.utc(year, month, 1);
    final monthEnd = DateTime.utc(year, month + 1, 1);

    return FutureBuilder<List<HabitLog>>(
      future:
          dao.getLogsForHabitInRange(habitId, monthStart.unixSeconds, monthEnd.unixSeconds),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
        }
        return _HeatmapGrid(
          logs: snap.data!,
          year: year,
          month: month,
        );
      },
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.logs,
    required this.year,
    required this.month,
  });

  final List<HabitLog> logs;
  final int year, month;

  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime.utc(year, month, 1);
    final totalDays = daysInMonth(year, month);
    final today = DateTime.now();

    // Build status map: day → status
    final statusMap = <int, LogStatus>{};
    for (final log in logs) {
      final d = dateFromUnix(log.date);
      if (d.year == year && d.month == month) {
        statusMap[d.day] = LogStatus.fromString(log.status);
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
                  _dayNames[i],
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
        ...List.generate(_weekCount(firstDay, totalDays), (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: List.generate(7, (weekday) {
                final day = week * 7 + weekday - (firstDay.weekday - 1) + 1;
                if (day < 1 || day > totalDays) {
                  return const Expanded(child: SizedBox(height: 36));
                }
                final isToday =
                    today.year == year && today.month == month && today.day == day;
                final status = statusMap[day];
                return Expanded(
                  child: _DayCell(
                    day: day,
                    status: status,
                    isToday: isToday,
                    isFuture: DateTime.utc(year, month, day).isAfter(today),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  int _weekCount(DateTime firstDay, int totalDays) {
    final offset = firstDay.weekday - 1; // Mon=0
    return ((offset + totalDays) / 7).ceil();
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
        case LogStatus.fail:
          bgColor = AppColors.dustyRose.withValues(alpha: 0.30);
        case LogStatus.pending:
          bgColor = theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.15);
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
          Text(
            '${(ratio * 100).round()}%',
            style: theme.textTheme.bodySmall,
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
// ── Edit Habit Sheet ────────────────────────────────────────
class _AllLogsSection extends ConsumerWidget {
  const _AllLogsSection({required this.habitId});

  final int habitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(habitLogsDaoProvider);
    return FutureBuilder<List<HabitLog>>(
      future: dao.getAllLogsForHabit(habitId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final logs = snap.data!;
        if (logs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Нет записей',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
          );
        }

        // Group by year-month
        final grouped = <(int, int), List<HabitLog>>{};
        for (final log in logs) {
          final d = dateFromUnix(log.date);
          grouped.putIfAbsent((d.year, d.month), () => []).add(log);
        }
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) {
            final cmp = b.$1.compareTo(a.$1);
            return cmp != 0 ? cmp : b.$2.compareTo(a.$2);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedKeys
              .map((k) => _MonthLogGroup(
                    year: k.$1,
                    month: k.$2,
                    logs: grouped[k]!,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _MonthLogGroup extends StatelessWidget {
  const _MonthLogGroup({
    required this.year,
    required this.month,
    required this.logs,
  });

  final int year, month;
  final List<HabitLog> logs;

  static const _months = [
    '', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = logs.where((l) => l.status == 'done').length;
    final skip = logs.where((l) => l.status == 'skip').length;
    final fail = logs.where((l) => l.status == 'fail').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Row(
            children: [
              Text(
                '${_months[month]} $year',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (done > 0)
                _LogBadge(icon: Icons.check_circle_outline,
                    color: AppColors.sageGreen, count: done),
              if (skip > 0) ...[
                const SizedBox(width: 6),
                _LogBadge(icon: Icons.pause_circle_outline,
                    color: AppColors.coolGreyBlue, count: skip),
              ],
              if (fail > 0) ...[
                const SizedBox(width: 6),
                _LogBadge(icon: Icons.cancel_outlined,
                    color: AppColors.dustyRose, count: fail),
              ],
            ],
          ),
        ),
        ...logs.map((log) => _LogTile(log: log)),
        const Divider(height: 1),
      ],
    );
  }
}

class _LogBadge extends StatelessWidget {
  const _LogBadge({required this.icon, required this.color, required this.count});

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
        Text('$count',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color)),
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
    final status = LogStatus.fromString(log.status);

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
            Text(hourStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.4),
                )),
        ],
      ),
    );
  }
}
