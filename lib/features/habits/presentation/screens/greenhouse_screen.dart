import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart' as enums;
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/habit_providers.dart';
import '../../domain/scheduling.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_sheet.dart';

/// Main daily screen — the "Greenhouse" (Теплица).
/// Shows today's habits grouped by time of day with a progress ring.
class GreenhouseScreen extends ConsumerStatefulWidget {
  const GreenhouseScreen({super.key});

  @override
  ConsumerState<GreenhouseScreen> createState() => _GreenhouseScreenState();
}

class _GreenhouseScreenState extends ConsumerState<GreenhouseScreen> {
  bool _hideCompleted = false;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final logsAsync = ref.watch(todayLogsProvider);
    final dayProgress = ref.watch(dayProgressProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
          data: (habits) {
            final logs = logsAsync.value ?? [];
            return _buildContent(context, theme, habits, logs, dayProgress);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: K.fabCreateHabit,
        onPressed: () => _showCreateHabitSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    List<Habit> habits,
    List<HabitLog> logs,
    double dayProgress,
  ) {
    // Group habits by time of day
    final groups = _groupByTimeOfDay(habits, logs);

    return CustomScrollView(
      slivers: [
        // ── Header with progress ring ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                _ProgressRing(key: K.progressRing, progress: dayProgress),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Теплица', style: theme.textTheme.headlineLarge),
                      Text(
                        _formatToday(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Hide completed toggle
                IconButton(
                  key: K.hideCompletedToggle,
                  onPressed: () => setState(() => _hideCompleted = !_hideCompleted),
                  icon: Icon(
                    _hideCompleted
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  tooltip: _hideCompleted
                      ? 'Показать выполненные'
                      : 'Скрыть выполненные',
                ),
              ],
            ),
          ),
        ),

        if (habits.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text('Нажмите + чтобы создать первую привычку',
                  key: K.emptyHabitsMessage),
            ),
          )
        else
          // ── Grouped habit lists ──
          for (final group in groups)
            ..._buildGroup(context, theme, group, logs),
      ],
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    ThemeData theme,
    _HabitGroup group,
    List<HabitLog> logs,
  ) {
    var items = group.habits;

    // Filter out completed if toggle is active
    if (_hideCompleted) {
      items = items.where((h) {
        final log = logs.where((l) => l.habitId == h.id).firstOrNull;
        return log == null || log.status != enums.LogStatus.done.name;
      }).toList();
    }

    if (items.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Icon(group.icon, size: 18, color: group.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: group.color,
                  ),
                ),
              ),
              // "Mark all" button (only for scheduled groups)
              if (group.showMarkAll)
                TextButton.icon(
                  key: K.markAllGroup(group.label),
                  onPressed: () => _markAllInGroup(items),
                  icon: Icon(Icons.done_all_rounded, size: 16, color: group.color),
                  label: Text(
                    'Всё',
                    style: theme.textTheme.labelSmall?.copyWith(color: group.color),
                  ),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final habit = items[index];
            final log = logs.where((l) => l.habitId == habit.id).firstOrNull;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: HabitCard(habit: habit, log: log),
            );
          },
        ),
      ),
    ];
  }

  void _markAllInGroup(List<Habit> habits) {
    HapticFeedback.heavyImpact();
    final actions = ref.read(habitActionsProvider.notifier);
    for (final habit in habits) {
      actions.markDone(habit.id);
    }
  }

  List<_HabitGroup> _groupByTimeOfDay(List<Habit> habits, List<HabitLog> logs) {
    final today = DateTime.now();
    final morning = <Habit>[];
    final afternoon = <Habit>[];
    final evening = <Habit>[];
    final anytime = <Habit>[];
    final notToday = <Habit>[];

    for (final h in habits) {
      if (!isExpectedToday(h, today)) {
        notToday.add(h);
        continue;
      }
      switch (enums.TimeOfDay.fromString(h.timeOfDay)) {
        case enums.TimeOfDay.morning:
          morning.add(h);
        case enums.TimeOfDay.afternoon:
          afternoon.add(h);
        case enums.TimeOfDay.evening:
          evening.add(h);
        case enums.TimeOfDay.anytime:
          anytime.add(h);
      }
    }

    return [
      if (morning.isNotEmpty)
        _HabitGroup(
          label: enums.TimeOfDay.morning.localizedName,
          icon: enums.TimeOfDay.morning.icon,
          color: enums.TimeOfDay.morning.color(context),
          habits: morning,
        ),
      if (afternoon.isNotEmpty)
        _HabitGroup(
          label: enums.TimeOfDay.afternoon.localizedName,
          icon: enums.TimeOfDay.afternoon.icon,
          color: enums.TimeOfDay.afternoon.color(context),
          habits: afternoon,
        ),
      if (evening.isNotEmpty)
        _HabitGroup(
          label: enums.TimeOfDay.evening.localizedName,
          icon: enums.TimeOfDay.evening.icon,
          color: enums.TimeOfDay.evening.color(context),
          habits: evening,
        ),
      if (anytime.isNotEmpty)
        _HabitGroup(
          label: enums.TimeOfDay.anytime.localizedName,
          icon: enums.TimeOfDay.anytime.icon,
          color: enums.TimeOfDay.anytime.color(context),
          habits: anytime,
        ),
      if (notToday.isNotEmpty)
        _HabitGroup(
          label: 'Не сегодня',
          icon: Icons.event_busy_outlined,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          habits: notToday,
          showMarkAll: false,
        ),
    ];
  }

  String _formatToday() {
    final now = DateTime.now();
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    const weekdays = [
      '', 'Понедельник', 'Вторник', 'Среда', 'Четверг',
      'Пятница', 'Суббота', 'Воскресенье',
    ];
    return '${weekdays[now.weekday]}, ${now.day} ${months[now.month]}';
  }

  void _showCreateHabitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const HabitFormSheet(),
    );
  }
}

// ── Progress Ring ────────────────────────────────────────────

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress * 100).round();

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor:
                theme.colorScheme.onSurface.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(
              progress >= 1.0
                  ? AppColors.emeraldGlow
                  : theme.colorScheme.primary,
            ),
            strokeCap: StrokeCap.round,
          ),
          Center(
            child: Text(
              '$pct%',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Habit Group model ────────────────────────────────────────

class _HabitGroup {
  const _HabitGroup({
    required this.label,
    required this.icon,
    required this.color,
    required this.habits,
    this.showMarkAll = true,
  });

  final String label;
  final IconData icon;
  final Color color;
  final List<Habit> habits;
  final bool showMarkAll;
}
