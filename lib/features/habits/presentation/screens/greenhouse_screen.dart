import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart' as enums;
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/habit_providers.dart';
import '../widgets/habit_card.dart';

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
              // "Mark all" button
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
    final morning = <Habit>[];
    final afternoon = <Habit>[];
    final evening = <Habit>[];
    final anytime = <Habit>[];

    for (final h in habits) {
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
          label: 'Утро',
          icon: Icons.wb_sunny_outlined,
          color: AppColors.sageGreen,
          habits: morning,
        ),
      if (afternoon.isNotEmpty)
        _HabitGroup(
          label: 'День',
          icon: Icons.wb_twilight_outlined,
          color: AppColors.warmAmber,
          habits: afternoon,
        ),
      if (evening.isNotEmpty)
        _HabitGroup(
          label: 'Вечер',
          icon: Icons.nightlight_outlined,
          color: AppColors.softLavender,
          habits: evening,
        ),
      if (anytime.isNotEmpty)
        _HabitGroup(
          label: 'Весь день',
          icon: Icons.schedule_outlined,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          habits: anytime,
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
      builder: (ctx) => const _CreateHabitSheet(),
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
  });

  final String label;
  final IconData icon;
  final Color color;
  final List<Habit> habits;
}

// ── Quick Create Habit Sheet ─────────────────────────────────

class _CreateHabitSheet extends ConsumerStatefulWidget {
  const _CreateHabitSheet();

  @override
  ConsumerState<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<_CreateHabitSheet> {
  final _nameController = TextEditingController();
  enums.FrequencyType _frequency = enums.FrequencyType.daily;
  enums.TimeOfDay _timeOfDay = enums.TimeOfDay.anytime;
  enums.SeedArchetype _archetype = enums.SeedArchetype.oak;
  final _selectedWeekdays = <int>{1, 2, 3, 4, 5};
  int _xValue = 3;
  int _everyXDays = 7;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: AppRadius.borderS,
                ),
              ),
            ),
            Text('Новая привычка', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),

            // ── Name ──
            TextField(
              key: K.habitNameField,
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(borderRadius: AppRadius.borderM),
              ),
            ),
            const SizedBox(height: 16),

            // ── Time of Day ──
            Text('Время дня', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: enums.TimeOfDay.values.map((t) {
                final label = switch (t) {
                  enums.TimeOfDay.morning => 'Утро',
                  enums.TimeOfDay.afternoon => 'День',
                  enums.TimeOfDay.evening => 'Вечер',
                  enums.TimeOfDay.anytime => 'Весь день',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: _timeOfDay == t,
                  onSelected: (_) => setState(() => _timeOfDay = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Frequency ──
            Text('Частота', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _freqChip('Каждый день', enums.FrequencyType.daily),
                _freqChip('Дни недели', enums.FrequencyType.weekdays),
                _freqChip('X раз/нед', enums.FrequencyType.xPerWeek),
                _freqChip('Каждые N дней', enums.FrequencyType.everyXDays),
                _freqChip('Негативная', enums.FrequencyType.negative),
              ],
            ),
            const SizedBox(height: 8),

            // Weekday selector
            if (_frequency == enums.FrequencyType.weekdays) ..._buildWeekdaySelector(theme),

            // X per week stepper
            if (_frequency == enums.FrequencyType.xPerWeek) ..._buildXStepper(
              theme,
              label: '$_xValue раз в неделю',
              value: _xValue,
              min: 1,
              max: 7,
              onChanged: (v) => setState(() => _xValue = v),
            ),

            // Every X days stepper
            if (_frequency == enums.FrequencyType.everyXDays) ..._buildXStepper(
              theme,
              label: 'Каждые $_everyXDays дней',
              value: _everyXDays,
              min: 2,
              max: 30,
              onChanged: (v) => setState(() => _everyXDays = v),
            ),
            const SizedBox(height: 16),

            // ── Seed Archetype ──
            Text('Семечко', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: enums.SeedArchetype.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final arch = enums.SeedArchetype.values[i];
                  final selected = _archetype == arch;
                  return GestureDetector(
                    onTap: () => setState(() => _archetype = arch),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.colorScheme.surface,
                        borderRadius: AppRadius.borderM,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _archetypeIcon(arch),
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            arch.displayName,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Create Button ──
            FilledButton(
              key: K.habitCreateButton,
              onPressed: _create,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
              ),
              child: const Text('Посадить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _freqChip(String label, enums.FrequencyType type) {
    return ChoiceChip(
      label: Text(label),
      selected: _frequency == type,
      onSelected: (_) => setState(() => _frequency = type),
    );
  }

  List<Widget> _buildWeekdaySelector(ThemeData theme) {
    const days = [
      (1, 'Пн'), (2, 'Вт'), (3, 'Ср'), (4, 'Чт'),
      (5, 'Пт'), (6, 'Сб'), (7, 'Вс'),
    ];
    return [
      Wrap(
        spacing: 6,
        children: days.map(((int n, String label) r) {
          final selected = _selectedWeekdays.contains(r.$1);
          return FilterChip(
            label: Text(r.$2),
            selected: selected,
            onSelected: (_) => setState(() {
              if (selected) {
                if (_selectedWeekdays.length > 1) _selectedWeekdays.remove(r.$1);
              } else {
                _selectedWeekdays.add(r.$1);
              }
            }),
          );
        }).toList(),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildXStepper(
    ThemeData theme, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Text(label, textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }

  IconData _archetypeIcon(enums.SeedArchetype arch) => switch (arch) {
        enums.SeedArchetype.oak => Icons.park_rounded,
        enums.SeedArchetype.sakura => Icons.filter_vintage_rounded,
        enums.SeedArchetype.pine => Icons.nature_rounded,
        enums.SeedArchetype.willow => Icons.grass_rounded,
        enums.SeedArchetype.baobab => Icons.forest_rounded,
        enums.SeedArchetype.palm => Icons.beach_access_rounded,
      };

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final freqValue = switch (_frequency) {
      enums.FrequencyType.weekdays =>
        jsonEncode({'days': _selectedWeekdays.toList()..sort()}),
      enums.FrequencyType.xPerWeek => jsonEncode({'x': _xValue}),
      enums.FrequencyType.everyXDays => jsonEncode({'x': _everyXDays}),
      _ => '{}',
    };

    ref.read(habitActionsProvider.notifier).createHabit(
          name: name,
          category: 'general',
          seedArchetype: _archetype,
          frequencyType: _frequency,
          frequencyValue: freqValue,
          timeOfDay: _timeOfDay,
        );

    Navigator.pop(context);
  }
}
