import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/providers/time_suggestions_provider.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/exposure.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../features/onboarding/app_tours.dart';
import '../../../../features/onboarding/feature_intro_trigger.dart';
import '../../../../features/onboarding/hint_tour.dart';
import '../../../../features/onboarding/single_hint.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../domain/today_board.dart';
import '../../../../core/settings/today.dart';
import '../../providers/habit_actions.dart';
import '../../providers/habit_metrics_providers.dart';
import '../../providers/habit_streams.dart';
import '../../providers/month_summary_providers.dart';
import '../../../week/providers/week_providers.dart';

import '../widgets/day_moment_card.dart';
import '../widgets/echo_card.dart';
import '../widgets/entrance.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/month_goals_card.dart';
import '../widgets/month_summary_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/swipe_hint_strip.dart';
import '../widgets/time_suggestion_banner.dart';
import '../widgets/today_group_visuals.dart';
import '../widgets/welcome_back_gate.dart';
import '../../../capsule/presentation/widgets/capsule_card.dart';
import '../../../capsule/providers/letter_providers.dart';
import '../../../week/presentation/widgets/week_summary_card.dart';

/// Minimum active habits before the «История» shortcut appears in the header.
const greenHouseHistoryMinHabits = 3;

/// Minimum habits in a single group before the hide-completed toggle appears.
const greenhouseToggleMinGroupHabits = 5;

/// Main daily screen — the "Greenhouse": today's habits grouped by time
/// of day with a progress ring.
/// One animated row of the Greenhouse board: either a group header or one
/// habit card. The id is the diff key between the current and the next set
/// of rows (section kinds are unique on the board).
sealed class _BoardEntry {
  String get id;
}

final class _GroupHeaderEntry extends _BoardEntry {
  _GroupHeaderEntry(this.group);

  final TodayGroup group;

  @override
  String get id => 'g:${group.kind.name}';
}

final class _HabitEntry extends _BoardEntry {
  _HabitEntry(this.habit, this.log);

  final Habit habit;
  final HabitLog? log;

  @override
  String get id => 'h:${habit.id}';
}

/// Which single banner the board may show today — at most one of the three
/// competing blocks (time suggestion, week summary, month summary). Time
/// suggestions win, then the summaries.
enum _HomeBanner { timeSuggestion, weekSummary, monthSummary }

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

  /// Just-completed habits that stay visible past the hide-completed filter
  /// while their card-level undo window is still open (deadline per id).
  final Map<int, DateTime> _graceUntil = <int, DateTime>{};

  /// The board's visible rows (group headers + habit cards) rendered by the
  /// animated sliver list. Kept in sync with [groupToday]'s output; when the
  /// two differ, the difference is applied as insert/remove animations.
  final GlobalKey<SliverAnimatedListState> _groupListKey =
      GlobalKey<SliverAnimatedListState>();
  List<_BoardEntry> _entries = const [];
  List<_BoardEntry>? _pendingNext;

  /// Whether the hide-completed toggle's one-time hint was attempted.
  bool _toggleHintTriggered = false;

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
    final openedAnyCapsule =
        ref.watch(capsuleFeedProvider).value?.opened.isNotEmpty ?? false;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            habitsAsync.when(
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
                  openedAnyCapsule,
                );
              },
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
    List<HabitLog> logs,
    double dayProgress,
    DateTime today,
    bool echoAtTop,
    bool openedAnyCapsule,
  ) {
    // Section ordering comes from the TodayBoard module — the screen only
    // renders. The hide-completed filter is a board rule too, so the toggle
    // just feeds it. Recently completed habits stay visible during their undo
    // window ([_graceUntil]) so the card can offer «Отменить» before it
    // slides away. Logs are indexed by habit id once here and shared with
    // both the board filter and the card list, so the index is never built
    // twice per frame.
    final logByHabit = {for (final l in logs) l.habitId: l};
    final groups = groupToday(
      habits: habits,
      today: today,
      logs: logs,
      hideCompleted: _hideCompleted,
      logByHabit: logByHabit,
      keepVisible: {
        for (final e in _graceUntil.entries)
          if (e.value.isAfter(DateTime.now())) e.key,
      },
    );

    // Feed the animated list: rows are derived here and diffed against the
    // current rows post-frame (build itself must not mutate the list).
    _syncEntries(_buildEntries(groups, logByHabit));

    // ── Header gating for newcomers ──
    // «История» only helps once there is something to look back on; the
    // hide-completed toggle only earns its place in a big group.
    final canSeeHistory = habits.length >= greenHouseHistoryMinHabits;
    final maxGroupSize = groups.fold(
      0,
      (max, g) => math.max(max, g.habits.length),
    );
    final canSeeToggle = maxGroupSize >= greenhouseToggleMinGroupHabits;

    // ── Single-banner arbitration ──
    final suggestionsAsync = ref.watch(timeSuggestionsProvider);
    final weekAsync = ref.watch(weekSummaryProvider);
    final monthAsync = ref.watch(monthSummaryProvider);

    final _HomeBanner? banner;
    if ((suggestionsAsync.value ?? const []).isNotEmpty) {
      banner = _HomeBanner.timeSuggestion;
    } else if (weekAsync.value?.shouldShow == true) {
      banner = _HomeBanner.weekSummary;
    } else if (monthAsync.value?.shouldShow == true) {
      banner = _HomeBanner.monthSummary;
    } else {
      banner = null;
    }

    final Widget? bannerWidget = switch (banner) {
      _HomeBanner.timeSuggestion => const TimeSuggestionBanner(),
      _HomeBanner.weekSummary => FeatureIntroTrigger(
        targetId: 'feature-week-summary',
        hintKey: 'feature-week-summary',
        minDays: 7,
        title: 'Итог недели',
        description:
            'По воскресеньям здесь мягкое резюме недели и намерение на следующую. Можно пропустить.',
        child: tourTarget('feature-week-summary', const WeekSummaryCard()),
      ),
      _HomeBanner.monthSummary => const MonthSummaryCard(),
      null => null,
    };

    // First-appearance tooltip for the hide-completed toggle.
    _maybeShowToggleHint(canSeeToggle);

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
                      onPressed: () =>
                          setState(() => _hideCompleted = !_hideCompleted),
                      icon: Icon(
                        _hideCompleted
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      tooltip: _hideCompleted
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

        if (echoAtTop)
          SliverToBoxAdapter(
            child: FeatureIntroTrigger(
              targetId: 'feature-echo',
              hintKey: 'feature-echo',
              minDays: 3,
              title: 'Открылось Эхо',
              description:
                  'Прошлые моменты появляются под Моментом дня. Тапни по карточке, чтобы раскрыть.',
              child: tourTarget('feature-echo', const EchoCard(atTop: true)),
            ),
          ),

        // ── Single banner (time suggestion → summaries) ──
        if (bannerWidget != null) SliverToBoxAdapter(child: bannerWidget),

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
                _entryRow(_entries[index], animation),
          ),

        // ── Reflection block (bottom): goals first ──
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
            title: 'Капсулы времени',
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
        if (!echoAtTop)
          SliverToBoxAdapter(
            child: FeatureIntroTrigger(
              targetId: 'feature-echo',
              hintKey: 'feature-echo',
              minDays: 3,
              title: 'Открылось Эхо',
              description:
                  'Прошлые моменты появляются под Моментом дня. Тапни по карточке, чтобы раскрыть.',
              child: tourTarget('feature-echo', const EchoCard()),
            ),
          ),
      ],
    );
  }

  /// Attempts the one-time hintful hint the first time the hide-completed
  /// toggle becomes visible. Show-once is owned by the hintful store.
  void _maybeShowToggleHint(bool canSeeToggle) {
    if (!canSeeToggle || _toggleHintTriggered) return;
    _toggleHintTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showSingleHint(
        context,
        ref,
        targetId: 'greenhouse-hide-toggle',
        title: 'Скрыть выполненные',
        description:
            'Когда привычек много — скрывай выполненные, чтобы видеть только то, что осталось.',
        id: 'greenhouse-hide-toggle',
      );
    });
  }

  /// Keeps a just-completed habit visible through its undo window when the
  /// hide-completed filter is on, so the card can show «Отменить» before it
  /// slides away.
  void _onHabitStatusChanged(int habitId) {
    if (!_hideCompleted) return;
    setState(() {
      _graceUntil[habitId] = DateTime.now().add(habitUndoWindow);
    });
    Timer(habitUndoWindow, () {
      if (!mounted) return;
      setState(() => _graceUntil.remove(habitId));
    });
  }

  /// Flattens the board into animated-list rows: one header entry per group,
  /// then one card entry per habit. The ids are the diff keys.
  List<_BoardEntry> _buildEntries(
    List<TodayGroup> groups,
    Map<int, HabitLog> logByHabit,
  ) {
    final out = <_BoardEntry>[];
    for (final group in groups) {
      if (group.habits.isEmpty) continue;
      out.add(_GroupHeaderEntry(group));
      for (final habit in group.habits) {
        out.add(_HabitEntry(habit, logByHabit[habit.id]));
      }
    }
    return out;
  }

  bool _sameEntries(List<_BoardEntry> next) {
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
  void _syncEntries(List<_BoardEntry> next) {
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
        var work = List<_BoardEntry>.of(_entries);
        while (mounted && !_sameEntries(next)) {
          var applied = 0;

          for (var i = work.length - 1; i >= 0 && applied < batchSize; i--) {
            if (nextIds.contains(work[i].id)) continue;
            final removed = work[i];
            list.removeItem(
              i,
              (context, animation) =>
                  _entryRow(removed, animation, removing: true),
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

  /// One animated-list row: header or card. Inserts grow from zero height
  /// with a fade, rise and slight scale — a living entrance instead of a
  /// flat expand. Removals collapse with a fade only (no travel). Reduced
  /// motion renders the row plainly.
  Widget _entryRow(
    _BoardEntry entry,
    Animation<double> animation, {
    bool removing = false,
  }) {
    final child = switch (entry) {
      _GroupHeaderEntry(:final group) => _buildGroupHeader(group),
      _HabitEntry(:final habit, :final log) => _buildHabitRow(habit, log),
    };
    if (AppMotion.mayDisable(context)) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOutStrong,
    );
    return SizeTransition(
      sizeFactor: animation,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curved,
        child: removing
            ? child
            : SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.09),
                  end: Offset.zero,
                ).animate(curved),
                child: ScaleTransition(
                  scale: Tween(begin: 0.95, end: 1.0).animate(curved),
                  child: child,
                ),
              ),
      ),
    );
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
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: _enteringIds.contains(habit.id)
            ? Entrance(
                onComplete: () {
                  if (mounted) {
                    setState(() => _enteringIds.remove(habit.id));
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

  void _markAllInGroup(List<Habit> habits) {
    Haptics.heavy(ref.read(hapticsEnabledProvider));
    ref.read(habitActionsProvider.notifier).logToday([
      for (final h in habits) h.id,
    ], status: LogStatus.done);
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
