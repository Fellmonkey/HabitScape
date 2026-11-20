import 'dart:async';

import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../domain/models/entities.dart';
import '../../../../features/onboarding/presentation/app_tours.dart';
import '../../../../features/onboarding/presentation/feature_intro_trigger.dart';
import '../../../../features/onboarding/presentation/hint_tour.dart';
import '../../../../features/onboarding/presentation/single_hint.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../shared/widgets/undo_feedback.dart';
import '../../../capsule/presentation/widgets/capsule_card.dart';
import '../../../capsule/providers/letter_providers.dart';
import '../../domain/today_board.dart';
import '../../providers/greenhouse_screen_controller.dart';
import '../../providers/habit_card_controller.dart';
import '../../providers/habit_metrics_providers.dart';
import '../../providers/habit_streams.dart';
import '../../providers/today_board_gating_provider.dart';
import '../../providers/today_board_provider.dart';
import '../widgets/banner_stack.dart';
import '../widgets/day_moment_card.dart';
import '../widgets/echo_card.dart';
import '../widgets/entrance.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/month_goals_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/swipe_hint_strip.dart';
import '../widgets/today_group_visuals.dart';
import '../widgets/welcome_back_gate.dart';
import 'greenhouse_board_rows.dart';

/// Main daily screen — the "Greenhouse": today's habits grouped by time
/// of day with a progress ring.
class GreenhouseScreen extends ConsumerStatefulWidget {
  const GreenhouseScreen({super.key});

  @override
  ConsumerState<GreenhouseScreen> createState() => _GreenhouseScreenState();
}

class _GreenhouseScreenState extends ConsumerState<GreenhouseScreen>
    with OnboardingTourMixin<GreenhouseScreen> {
  /// The board's visible rows (group headers + habit cards) rendered by the
  /// animated sliver list. Kept in sync with `todayBoardProvider`; when the
  /// two differ, the difference is applied as insert/remove animations.
  final GlobalKey<SliverAnimatedListState> _groupListKey =
      GlobalKey<SliverAnimatedListState>();
  List<BoardEntry> _entries = const [];
  List<BoardEntry>? _pendingNext;

  /// One-shot decisions and the group undo window live in
  /// `GreenhouseScreenController` (see providers/greenhouse_screen_controller).

  bool _effectsScheduled = false;

  @override
  String get tourScope => AppTourIds.greenhouse;

  @override
  void initState() {
    super.initState();
    _scheduleEffects();
  }

  /// One-shot effects and animated-list sync run after the frame from this
  /// scheduler; listeners register in build, which itself stays declarative.
  void _scheduleEffects() {
    if (_effectsScheduled) return;
    _effectsScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _effectsScheduled = false;
      if (!mounted) return;
      final habits = ref.read(activeHabitsProvider).value ?? const <Habit>[];
      final controller = ref.read(greenhouseScreenControllerProvider.notifier);

      if (controller.checkDayClosed(
        hasHabits: habits.isNotEmpty,
        progress: ref.read(dayProgressProvider),
        today: ref.read(todayDateProvider),
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            key: K.dayClosed,
            duration: Duration(seconds: 4),
            content: Text('День закрыт! 🎉 Все привычки выполнены.'),
          ),
        );
      }

      final board = ref.read(todayBoardProvider);
      _syncEntries(buildBoardEntries(board.groups, board.logByHabit));

      if (controller.claimToggleHint(
        canSeeToggle: ref.read(todayBoardGatingProvider).canSeeToggle,
      )) {
        showSingleHint(
          context,
          ref,
          targetId: 'greenhouse-hide-toggle',
          title: 'Скрыть выполненные',
          description:
              'Когда привычек много — скрывай выполненные, чтобы видеть только то, что осталось.',
          id: 'greenhouse-hide-toggle',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(activeHabitsProvider);
    final board = ref.watch(todayBoardProvider);
    final dayProgress = ref.watch(dayProgressProvider);
    final today = ref.watch(todayDateProvider);
    final gating = ref.watch(todayBoardGatingProvider);
    ref.listen(todayBoardProvider, (_, _) => _scheduleEffects());
    ref.listen(todayBoardGatingProvider, (_, _) => _scheduleEffects());
    final theme = Theme.of(context);

    final openedAnyCapsule =
        ref.watch(capsuleFeedProvider).value?.opened.isNotEmpty ?? false;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            habitsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Ошибка: $e')),
              data: (habits) => _buildContent(
                context,
                theme,
                habits,
                dayProgress,
                today,
                openedAnyCapsule,
                gating,
                board,
              ),
            ),
            // Renders nothing; owns the once-per-absence return welcome.
            const WelcomeBackGate(),
          ],
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
    double dayProgress,
    DateTime today,
    bool openedAnyCapsule,
    TodayBoardGating gating,
    TodayBoardSnapshot board,
  ) {
    // The board shape (grouping, hide-completed filter, undo grace) is derived
    // by `todayBoardProvider`; this method only renders it.

    // ── Header gating for newcomers ──
    // «История» only helps once there is something to look back on; the
    // hide-completed toggle appears once the board is big enough (5+ habits
    // total — spreading across groups shouldn't hide a useful control).
    final canSeeHistory = gating.canSeeHistory;
    final canSeeToggle = gating.canSeeToggle;

    // State and one-shot effects are driven by `_scheduleEffects` (listeners
    // registered in build); this method only derives and renders.
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
                if (canSeeHistory)
                  tourTarget(
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
                if (canSeeToggle)
                  tourTarget(
                    'greenhouse-hide-toggle',
                    IconButton(
                      key: K.hideCompletedToggle,
                      onPressed: () => ref
                          .read(todayBoardViewControllerProvider.notifier)
                          .toggleHideCompleted(),
                      icon: Icon(
                        board.view.hideCompleted
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      tooltip: board.view.hideCompleted
                          ? 'Показать выполненные'
                          : 'Скрыть выполненные',
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Day moment ──
        SliverToBoxAdapter(
          child: tourTarget(AppHintIds.greenhouseMoment, const DayMomentCard()),
        ),

        // Echo is always placed here — one stable position above the habit
        // list, so the feature reads as reliable (visibility = cooldown).
        SliverToBoxAdapter(
          child: FeatureIntroTrigger(
            targetId: 'feature-echo',
            hintKey: 'feature-echo',
            minDays: 3,
            title: 'Открылось Эхо',
            description:
                'Прошедшие моменты появляются под Моментом дня. Нажми на карточку, чтобы раскрыть.',
            child: tourTarget('feature-echo', const EchoCard(atTop: true)),
          ),
        ),

        // ── Stacked banner pile (time suggestion + summaries) ──
        const SliverToBoxAdapter(child: BannerStack()),

        // ── One-time swipe teaching strip ──
        if (habits.isNotEmpty)
          const SliverToBoxAdapter(child: SwipeHintStrip()),

        if (habits.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_florist_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Здесь будет твой день',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите + чтобы создать первую привычку',
                      key: K.emptyHabitsMessage,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // ── Grouped habit lists ──
          SliverAnimatedList(
            key: _groupListKey,
            initialItemCount: _entries.length,
            itemBuilder: (context, index, animation) =>
                boardEntryRow(
                  context,
                  _entries[index],
                  animation,
                  headerBuilder: _buildGroupHeader,
                  cardBuilder: _buildHabitRow,
                ),
          ),

        // ── Reflection block (bottom): goals first ──
        // Hidden until the first habit exists — an empty board must stay
        // quiet, without extra meta-cards next to the empty state.
        if (habits.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
              child: const AppSectionHeader(
                icon: Icons.self_improvement_rounded,
                title: 'Рефлексия',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FeatureIntroTrigger(
              targetId: 'feature-month-goals',
              hintKey: 'feature-month-goals',
              minDays: 14,
              title: 'Цели месяца',
              description:
                  'Чего достичь через привычки в этом месяце? Добавь цель одним тапом.',
              child: tourTarget('feature-month-goals', const MonthGoalsCard()),
            ),
          ),
          SliverToBoxAdapter(
            child: FeatureIntroTrigger(
              // Reminder: the invite matured but no capsule was opened within
              // a week of it (30 + 7 days).
              targetId: 'feature-capsules-reminder',
              hintKey: 'feature-capsules-reminder',
              minDays: 37,
              enabled: !openedAnyCapsule,
              title: 'Письмо из прошлого',
              description:
                  'Ты ещё не открывал письма из прошлого — загляни в Капсулы.',
              child: FeatureIntroTrigger(
                targetId: 'feature-capsules',
                hintKey: 'feature-capsules',
                minDays: 30,
                title: 'Капсулы времени',
                description:
                    'Напиши письмо себе — и через месяц оно откроется, как маленький сюрприз.',
                child: tourTarget('feature-capsules', const CapsuleCard()),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Keeps a just-completed habit visible through its undo window when the
  /// hide-completed filter is on, so the card can show «Отменить» before it
  /// slides away.
  void _onHabitStatusChanged(int habitId) {
    if (!ref.read(todayBoardViewControllerProvider).hideCompleted) return;
    final controller = ref.read(todayBoardViewControllerProvider.notifier);
    controller.keepVisible([habitId], ref.read(clockProvider).now().add(habitUndoWindow));
    Timer(habitUndoWindow, () {
      if (!mounted) return;
      controller.release([habitId]);
    });
  }

  bool _sameEntries(List<BoardEntry> next) {
    final current = _entries;
    if (next.length != current.length) return false;
    for (var i = 0; i < next.length; i++) {
      if (next[i].id != current[i].id) return false;
    }
    return true;
  }

  /// True while an apply loop is running. Because applying is now async
  /// (it waits between batches), a second [._syncEntries] during that time
  /// must not start a competing loop against the same list — it would apply
  /// stale indices concurrently and crash with a RangeError. Instead the new
  /// target replaces [._pendingNext] and the running loop picks it up after
  /// the current one finishes.
  bool _applyingEntries = false;

  /// Schedules one post-frame apply of [next]. Build may run many times per
  /// frame; only the latest pending list is applied, and only when it
  /// actually differs from what the animated list shows.
  void _syncEntries(List<BoardEntry> next) {
    if (_sameEntries(next)) return;
    _pendingNext = next;
    if (_applyingEntries) return; // the running loop will see the new target
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPendingEntries());
  }

  Future<void> _applyPendingEntries() async {
    if (_applyingEntries) return;
    _applyingEntries = true;
    // Resolve once before any async gap; reduced-motion is a stable screen
    // property for the duration of this loop.
    final mayDisable = AppMotion.mayDisable(context);
    try {
      // Drain every pending target in order. New targets arriving mid-apply
      // replace [_pendingNext] and are handled by the next loop iteration.
      while (mounted) {
        final next = _pendingNext;
        if (next == null) break;
        _pendingNext = null;
        if (_sameEntries(next)) continue;

        final list = _groupListKey.currentState;
        if (list == null || mayDisable) {
          setState(() => _entries = next);
          continue;
        }

        // Split a large diff into roughly equal batches (about three waves),
        // so a board with many habits updates continuously — a few rows
        // appear or disappear at a time — instead of trying to animate
        // everything in one frame and stalling. Small diffs (≤8 rows) apply
        // in a single shot.
        final currentIds = {for (final e in _entries) e.id};
        final nextIds = {for (final e in next) e.id};
        final shared = currentIds.intersection(nextIds).length;
        final totalChanges =
            (_entries.length - shared) + (next.length - shared);
        final batchSize = totalChanges > 8
            ? (totalChanges + 2) ~/ 3
            : totalChanges;

        // Apply the diff in batches: remove up to [batchSize] rows (back to
        // front, so indices stay valid), insert up to the remaining batch
        // capacity (positionally matching the target), then wait for those
        // animations to finish before the next batch — the list stays in
        // sync with [_entries] at every step because every mutation goes
        // through the animated list's own API.
        var work = List<BoardEntry>.of(_entries);
        while (mounted && !_sameEntries(next)) {
          var applied = 0;

          for (var i = work.length - 1; i >= 0 && applied < batchSize; i--) {
            if (nextIds.contains(work[i].id)) continue;
            final removed = work[i];
            list.removeItem(
              i,
              (context, animation) =>
                  boardEntryRow(
                    context,
                    removed,
                    animation,
                    headerBuilder: _buildGroupHeader,
                    cardBuilder: _buildHabitRow,
                    removing: true,
                  ),
              duration: AppMotion.travel,
            );
            work.removeAt(i);
            applied++;
          }

          var wi = 0;
          for (var ni = 0; ni < next.length && applied < batchSize; ni++) {
            if (wi < work.length && work[wi].id == next[ni].id) {
              wi++;
              continue;
            }
            list.insertItem(wi, duration: AppMotion.travel);
            work.insert(wi, next[ni]);
            wi++;
            applied++;
          }

          _entries = work;
          if (applied == 0) break;
          await Future<void>.delayed(AppMotion.travel);
        }
      }
    } finally {
      _applyingEntries = false;
    }
  }

  Widget _buildGroupHeader(TodayGroup group) {
    final theme = Theme.of(context);
    final (label, icon, color) = todayGroupVisuals(group.kind, context);

    return Padding(
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
              onPressed: () => _markAllInGroup(group.habits),
              icon: Icon(Icons.done_all_rounded, size: 16, color: color),
              label: Text(
                'Выполнить все',
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHabitRow(Habit habit, HabitLog? log) {
    // The Dismissible lives inside the card itself — the card owns its status
    // changes, so the undo affordance works identically for taps and swipes.
    final entering = ref.read(todayBoardViewControllerProvider).enteringIds;
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: entering.contains(habit.id)
            ? Entrance(
                onComplete: () {
                  if (mounted) {
                    ref
                        .read(todayBoardViewControllerProvider.notifier)
                        .removeEntering(habit.id);
                  }
                },
                child: HabitCard(
                  habit: habit,
                  log: log,
                  onStatusChanged: () => _onHabitStatusChanged(habit.id),
                ),
              )
            : HabitCard(
                habit: habit,
                log: log,
                onStatusChanged: () => _onHabitStatusChanged(habit.id),
              ),
      ),
    );
  }

  Future<void> _markAllInGroup(List<Habit> habits) async {
    final ids = [for (final h in habits) h.id];

    Haptics.heavy(ref.read(hapticsEnabledProvider));
    final vm = ref.read(greenhouseScreenControllerProvider.notifier);
    final previous = await vm.markAllInGroup(ids);
    if (!mounted) return;

    showUndoSnackBar(
      context,
      message: 'Выполнено: ${ids.length}',
      label: 'Отменить всё',
      duration: groupUndoWindow,
      onUndo: () => vm.undoGroup(ids, previous),
    );
  }

  String _formatToday(DateTime today) => formatFullDate(today);

  Future<void> _showCreateHabitSheet(BuildContext context) async {
    final createdId = await AppSheets.show<int>(
      context,
      builder: (ctx) => const HabitFormSheet(),
    );
    if (createdId != null && mounted) {
      ref
          .read(todayBoardViewControllerProvider.notifier)
          .addEntering(createdId);
    }
  }
}
