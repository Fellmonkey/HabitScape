import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart' as enums;
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/shared_prefs.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../features/onboarding/app_tours.dart';
import '../../../../features/onboarding/hint_tour.dart';
import '../../../../features/onboarding/onboarding_flags.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../domain/scheduling.dart';
import '../../providers/habit_providers.dart';
import '../../../onboarding/feature_hints.dart';

import '../widgets/day_moment_card.dart';
import '../widgets/echo_card.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/month_goals_card.dart';
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

  bool _echoTopResolved = false;
  bool _echoAtTop = true;

  @override
  String get tourScope => OnboardingTours.greenhouse;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final logsAsync = ref.watch(todayLogsProvider);
    final dayProgress = ref.watch(dayProgressProvider);
    final prefsAsync = ref.watch(sharedPrefsProvider);
    if (!_echoTopResolved && prefsAsync.hasValue) {
      final prefs = prefsAsync.value!;
      final today = DateTime.now().toMidnight.unixSeconds;
      final key = 'echo_shown_count_$today';
      final count = prefs.getInt(key) ?? 0;
      if (count < 2) {
        _echoAtTop = true;
        prefs.setInt(key, count + 1);
      } else {
        _echoAtTop = false;
      }
      _echoTopResolved = true;
    }
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
  ) {
    // Index logs by habit id so per-habit lookup is O(1).
    final groups = _groupByTimeOfDay(habits, logs);
    final logByHabit = {for (final l in logs) l.habitId: l};

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

        if (_echoAtTop)
          const SliverToBoxAdapter(child: EchoCard()),

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
        if (!_echoAtTop)
          const SliverToBoxAdapter(child: EchoCard()),
      ],
    );
  }

  List<Widget> _buildGroup(
    BuildContext context,
    ThemeData theme,
    _HabitGroup group,
    Map<int, HabitLog> logByHabit,
  ) {
    var items = group.habits;

    if (_hideCompleted) {
      items = items.where((h) {
        final log = logByHabit[h.id];
        return log == null || log.status != enums.LogStatus.done;
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
                  icon: Icon(
                    Icons.done_all_rounded,
                    size: 16,
                    color: group.color,
                  ),
                  label: Text(
                    'Выполнить все',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: group.color,
                    ),
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
                    child: const Icon(Icons.check_rounded, color: AppColors.emeraldGlow),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: AppColors.coolGreyBlue.withValues(alpha: 0.18),
                    child: const Icon(Icons.pause_rounded, color: AppColors.coolGreyBlue),
                  ),
                  movementDuration: const Duration(milliseconds: 220),
                  resizeDuration: const Duration(milliseconds: 220),
                  dismissThresholds: const {
                    DismissDirection.horizontal: 0.35,
                  },
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await ref.read(habitActionsProvider.notifier).markDone(habit.id);
                    } else {
                      await ref.read(habitActionsProvider.notifier).markSkip(habit.id);
                    }
                    return false;
                  },
                  child: _enteringIds.contains(habit.id)
                      ? _Entrance(
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
    ref.read(habitActionsProvider.notifier).markAllDone([
      // one batched write
      for (final h in habits) h.id,
    ]);
  }

  List<_HabitGroup> _groupByTimeOfDay(List<Habit> habits, List<HabitLog> logs) {
    final today = DateTime.now();
    final focus = <Habit>[];
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
      // Focus habits get their own section at the top — that is the whole
      // point of marking 1–5 habits as focus.
      if (h.isFocus) {
        focus.add(h);
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
      if (focus.isNotEmpty)
        _HabitGroup(
          label: 'Фокус',
          icon: Icons.star_rounded,
          color: AppColors.warmAmber,
          habits: focus,
          showMarkAll: false,
        ),
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

  String _formatToday() => formatFullDate(DateTime.now());

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

// ── Progress Ring ────────────────────────────────────────────

class _ProgressRing extends StatefulWidget {
  const _ProgressRing({super.key, required this.progress});

  final double progress;

  @override
  State<_ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<_ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: AppMotion.slow);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _pulse, curve: AppMotion.easeOutStrong));
  }

  @override
  void didUpdateWidget(covariant _ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pulse only when today's completion grows — feedback, not decoration.
    if (!AppMotion.mayDisable(context) &&
        widget.progress > oldWidget.progress) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (widget.progress * 100).round();

    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: widget.progress,
              strokeWidth: 5,
              backgroundColor: theme.colorScheme.onSurface.withValues(
                alpha: 0.1,
              ),
              valueColor: AlwaysStoppedAnimation(
                widget.progress >= 1.0
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
      ),
    );
  }
}

/// One-shot entrance for a newly created habit: fade + rise + a water ring
/// bursting near the icon («капля о воду»). Reduced-motion users get the row
/// instantly.
class _Entrance extends StatefulWidget {
  const _Entrance({required this.child, required this.onComplete});

  final Widget child;
  final VoidCallback onComplete;

  /// Wait for the creating sheet to finish closing (150ms exit + margin) so
  /// the entrance plays on a fully visible screen.
  static const startDelay = Duration(milliseconds: 180);

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _rise;
  late final Animation<double> _cardScale;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.slow);
    final curve = CurvedAnimation(parent: _c, curve: AppMotion.easeOutStrong);
    _fade = Tween(begin: 0.0, end: 1.0).animate(curve);
    _rise = Tween(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(curve);
    _cardScale = Tween(begin: 0.96, end: 1.0).animate(curve);
    _ringScale = Tween(begin: 0.6, end: 2.4).animate(curve);
    _ringOpacity = Tween(begin: 0.5, end: 0.0).animate(curve);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(_Entrance.startDelay, () {
        if (mounted) _c.forward().whenComplete(widget.onComplete);
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.mayDisable(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onComplete());
      return widget.child;
    }
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _rise,
        child: ScaleTransition(
          scale: _cardScale,
          child: Stack(
            children: [
              widget.child,
              Positioned(
                right: 46,
                top: 18,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => Container(
                    width: 28 * _ringScale.value,
                    height: 28 * _ringScale.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.emeraldGlow.withValues(
                          alpha: _ringOpacity.value,
                        ),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
