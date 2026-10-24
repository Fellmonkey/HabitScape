import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart' as enums;
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/exposure.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/onboarding/app_tours.dart';
import '../../../../features/onboarding/hint_tour.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../domain/today_board.dart';
import '../../../../core/settings/today.dart';
import '../../providers/habit_actions.dart';
import '../../providers/habit_metrics_providers.dart';
import '../../providers/habit_streams.dart';
import '../../../onboarding/feature_hints.dart';

import '../widgets/day_moment_card.dart';
import '../widgets/echo_card.dart';
import '../widgets/entrance.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/month_goals_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/today_group_visuals.dart';
import '../../../capsule/presentation/widgets/capsule_card.dart';
import '../../../week/presentation/widgets/week_summary_card.dart';

/// Main daily screen — the "Greenhouse": today's habits grouped by time
/// of day with a progress ring.
class GreenhouseScreen extends ConsumerStatefulWidget {
  const GreenhouseScreen({super.key});

  @override
  ConsumerState<GreenhouseScreen> createState() => _GreenhouseScreenState();
}

class _GreenhouseScreenState extends ConsumerState<GreenhouseScreen>
    with OnboardingTourMixin<GreenhouseScreen> {
  bool _hideCompleted = false;

  /// Habit ids created in this session — they get a one-shot entrance.
  final Set<int> _enteringIds = <int>{};

  @override
  String get tourScope => AppTourIds.greenhouse;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final logsAsync = ref.watch(todayLogsProvider);
    final dayProgress = ref.watch(dayProgressProvider);
    final today = ref.watch(todayDateProvider);
    final theme = Theme.of(context);

    // Echo placement is a provider decision, not a post-mount setState: the
    // weekly top quota drives it reactively, and the card charges the quota
    // itself on mount (see [EchoCard.atTop]).
    final echoAtTop = ref.watch(exposureProvider).value?.echoAtTop ?? true;

    return Scaffold(
      body: SafeArea(
        child: habitsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
          data: (habits) {
            final logs = logsAsync.value ?? [];
            return _buildContent(
              context,
              theme,
              habits,
              logs,
              dayProgress,
              today,
              echoAtTop,
            );
          },
        ),
      ),
      floatingActionButton: PressableScale(
        child: FloatingActionButton(
          key: K.fabCreateHabit,
          onPressed: () => _showCreateHabitSheet(context),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    List<Habit> habits,
    List<HabitLog> logs,
    double dayProgress,
    DateTime today,
    bool echoAtTop,
  ) {
    // Section ordering comes from the TodayBoard module — the screen only
    // renders. The hide-completed filter is a board rule too, so the toggle
    // just feeds it. Logs are indexed by habit id so per-habit lookup is O(1).
    final groups = groupToday(
      habits: habits,
      today: today,
      logs: logs,
      hideCompleted: _hideCompleted,
    );
    final logByHabit = {for (final l in logs) l.habitId: l};

    return CustomScrollView(
      slivers: [
        // ── Header with progress ring ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                ProgressRing(key: K.progressRing, progress: dayProgress),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Теплица', style: theme.textTheme.headlineLarge),
                      Text(
                        _formatToday(today),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                hintTarget(
                  AppHintIds.greenhouseSpread,
                  OutlinedButton.icon(
                    key: K.openMonthSpread,
                    onPressed: () => context.push('/month'),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: const Text('История'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                // Hide completed toggle
                IconButton(
                  key: K.hideCompletedToggle,
                  onPressed: () =>
                      setState(() => _hideCompleted = !_hideCompleted),
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

        // ── Day moment ──
        SliverToBoxAdapter(
          child: hintTarget(AppHintIds.greenhouseMoment, const DayMomentCard()),
        ),

        if (echoAtTop) const SliverToBoxAdapter(child: EchoCard(atTop: true)),

        const SliverToBoxAdapter(child: WeekSummaryCard()),

        const SliverToBoxAdapter(child: FeatureHintBanner()),

        if (habits.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Нажмите + чтобы создать первую привычку',
                key: K.emptyHabitsMessage,
              ),
            ),
          )
        else
          // ── Grouped habit lists ──
          for (final group in groups)
            ..._buildGroup(context, theme, group, logByHabit),

        // -- Reflection block (bottom): goals first --
        const SliverToBoxAdapter(child: MonthGoalsCard()),
        const SliverToBoxAdapter(child: CapsuleCard()),
        if (!echoAtTop) const SliverToBoxAdapter(child: EchoCard()),
      ],
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    ThemeData theme,
    TodayGroup group,
    Map<int, HabitLog> logByHabit,
  ) {
    final items = group.habits;
    final (label, icon, color) = todayGroupVisuals(group.kind, context);

    if (items.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
              // "Mark all" button (only for scheduled groups)
              if (group.canMarkAll)
                TextButton.icon(
                  key: K.markAllGroup(label),
                  onPressed: () => _markAllInGroup(items),
                  icon: Icon(Icons.done_all_rounded, size: 16, color: color),
                  label: Text(
                    'Выполнить все',
                    style: theme.textTheme.labelSmall?.copyWith(color: color),
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
            final log = logByHabit[habit.id];
            // Isolates card animations so one card doesn't repaint the sliver.
            return RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Dismissible(
                  key: K.habitCard(habit.id),
                  direction: DismissDirection.horizontal,
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    color: AppColors.emeraldGlow.withValues(alpha: 0.18),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.emeraldGlow,
                    ),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.coolGreyBlue.withValues(alpha: 0.18),
                    child: const Icon(
                      Icons.pause_rounded,
                      color: AppColors.coolGreyBlue,
                    ),
                  ),
                  movementDuration: const Duration(milliseconds: 220),
                  resizeDuration: const Duration(milliseconds: 220),
                  dismissThresholds: const {DismissDirection.horizontal: 0.35},
                  confirmDismiss: (direction) async {
                    final actions = ref.read(habitActionsProvider.notifier);
                    if (direction == DismissDirection.startToEnd) {
                      await actions.logToday([
                        habit.id,
                      ], status: enums.LogStatus.done);
                    } else {
                      await actions.logToday([
                        habit.id,
                      ], status: enums.LogStatus.skip);
                    }
                    return false;
                  },
                  child: _enteringIds.contains(habit.id)
                      ? Entrance(
                          onComplete: () {
                            if (mounted) {
                              setState(() => _enteringIds.remove(habit.id));
                            }
                          },
                          child: HabitCard(habit: habit, log: log),
                        )
                      : HabitCard(habit: habit, log: log),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  void _markAllInGroup(List<Habit> habits) {
    Haptics.heavy(ref.read(hapticsEnabledProvider));
    ref.read(habitActionsProvider.notifier).logToday([
      for (final h in habits) h.id,
    ], status: enums.LogStatus.done);
  }

  String _formatToday(DateTime today) => formatFullDate(today);

  Future<void> _showCreateHabitSheet(BuildContext context) async {
    final createdId = await AppSheets.show<int>(
      context,
      builder: (ctx) => const HabitFormSheet(),
    );
    if (createdId != null && mounted) {
      setState(() => _enteringIds.add(createdId));
    }
  }
}
