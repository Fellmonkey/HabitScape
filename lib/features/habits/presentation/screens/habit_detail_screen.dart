import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheets.dart';

import '../../providers/habit_providers.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/habit_info_row.dart';
import '../widgets/history_sliver.dart';
import '../widgets/month_heatmap.dart';
import '../widgets/month_stats_section.dart';
import '../widgets/time_distribution_section.dart';
import '../../domain/habit_engine.dart';

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
                    HabitInfoRow(habit: habit),
                    const SizedBox(height: 20),

                    if (_tab == 0) ...[
                      metricsAsync.when(
                        loading: () => const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('Ошибка метрик: $e'),
                        data: (m) => MonthStatsSection(
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
                      MonthHeatmap(
                        habitId: habitId,
                        year: now.year,
                        month: now.month,
                      ),
                      const SizedBox(height: 24),

                      metricsAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (m) => TimeDistributionSection(metrics: m),
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
                  sliver: HistorySection(habitId: habitId),
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
        return;
      case 'focus':
        final ok = await actions.setFocus(habitId, isFocus: true);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Максимум 5 фокусных привычек')),
          );
        }
        return;
      case 'unfocus':
        await actions.setFocus(habitId, isFocus: false);
        return;
      case 'archive':
        await actions.setLifecycle(habitId, HabitLifecycle.archive);
        if (context.mounted) nav.pop();
        return;
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
        return;
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
        Text('Ночь: ${(metrics.nightRatio * 100).round()}%'),
      ],
    );
  }
}
