import 'dart:async';

import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../domain/enums.dart';
import '../../../../domain/models/entities.dart';
import '../../../../shared/widgets/error_feedback.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../providers/habit_actions.dart';
import '../../providers/habit_card_controller.dart';
import '../../providers/habit_streams.dart';
import 'habit_card_bits.dart';

/// A single habit row in the Greenhouse list: tap the check circle to mark
/// done, tap the card to open details.
///
/// Status changes (tap or swipe) open a short undo window: the card shows a
/// «Отменить» action and a soft pulsing glow that previews the card's
/// disappearance (used by the hide-completed view). Reduced-motion users get
/// the undo action without the glow.
class HabitCard extends ConsumerStatefulWidget {
  const HabitCard({
    required this.habit,
    required this.log,
    this.onStatusChanged,
    super.key,
  });

  final Habit habit;
  final HabitLog? log;

  /// Invoked after a status change is applied (used by the screen to keep a
  /// just-completed card visible during its undo window).
  final VoidCallback? onStatusChanged;

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnim;

  /// The habit's log status for today, read live from the logs stream (not
  /// from the pinned [HabitCard.log] prop): the animated list may keep this
  /// row alive with stale data. Computed on demand so `build` stays declarative.
  LogStatus? _statusNow() {
    return ref.read(todayLogForHabitProvider(widget.habit.id))?.status ??
        widget.log?.status;
  }

  /// Optimistic status and undo window live in `HabitCardController`; this
  /// state class keeps only animation controllers and paint concerns.

  /// Soft pulsing glow while the undo window is open — previews that the
  /// card is about to leave the board (hide-completed view). Paint-only
  /// (box shadow / border), disabled under reduced motion.
  late final AnimationController _glowController;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _scaleAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.05), weight: 35),
          TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.98), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 0.98, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(
            parent: _bounceController,
            curve: AppMotion.easeOutStrong,
          ),
        );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: AppMotion.easeInOutStrong,
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Applies [status] (done / skip) and opens the undo window with the
  /// pre-change status. Shared by the check-circle tap and the swipe.
  Future<void> _applyStatus(LogStatus status) async {
    final previous = _statusNow();
    if (previous == status) return;

    if (status == LogStatus.done) {
      Haptics.medium(ref.read(hapticsEnabledProvider));
      if (!AppMotion.mayDisable(context)) {
        _bounceController.forward(from: 0);
      }
    } else {
      Haptics.tap(ref.read(hapticsEnabledProvider));
    }

    // The ViewModel owns the optimistic status and the undo window; the card
    // only triggers it and rolls it back if the write fails.
    ref
        .read(habitCardControllerProvider(widget.habit.id).notifier)
        .beginApply(status, previous);

    try {
      await ref.read(habitActionsProvider.notifier).logToday([
        widget.habit.id,
      ], status: status);
      widget.onStatusChanged?.call();
      // A swipe-left is a skip — never a delete. Teach this quietly on the
      // very first skip so the gesture isn't misread later.
      if (status == LogStatus.skip) {
        await _maybeTeachFirstSkip();
      }
    } catch (error) {
      if (mounted) {
        ref
            .read(habitCardControllerProvider(widget.habit.id).notifier)
            .failApply();
        showErrorSnackBar(context, error);
      }
    }
  }

  /// One-time hint attached to the first skip gesture: «это пропуск, а не
  /// удаление». Show-once is owned by Exposure.
  Future<void> _maybeTeachFirstSkip() async {
    if (!mounted) return;
    final show = await ref.read(habitActionsProvider.notifier).takeFirstSkipHint();
    if (!mounted || !show) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Это пропуск — привычка остаётся в списке. Свайп вправо — «выполнить».',
        ),
      ),
    );
  }

  Future<void> _undo() async {
    try {
      await ref
          .read(habitCardControllerProvider(widget.habit.id).notifier)
          .undo(widget.habit.id);
    } catch (error) {
      // The stream will settle on whatever state survived the failed write;
      // the user still learns that the undo did not go through.
      if (mounted) showErrorSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Keep the visible status in sync with the live logs stream. The board
    // list may keep this row alive with a stale log prop, so the source of
    // truth for "is it done" is the stream, not the prop.
    // Watch the stream so a write rebuilds the row; read the value without
    // mutating widget state during build.
    ref.watch(todayLogForHabitProvider(widget.habit.id));
    final status = _statusNow();
    final today = ref.watch(todayDateProvider);
    final cardState = ref.watch(habitCardControllerProvider(widget.habit.id));

    // Animation control is a UI concern; the listener reacts to ViewModel
    // changes instead of mutating widget state from build.
    ref.listen(habitCardControllerProvider(widget.habit.id), (_, next) {
      if (next.undoOpen && !AppMotion.mayDisable(context)) {
        if (!_glowController.isAnimating) _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.value = 0;
      }
    });

    final isDone = status == LogStatus.done || cardState.optimisticDone;
    final showUndo = cardState.undoOpen;

    final card = ScaleTransition(
      scale: _scaleAnim,
      child: Card(
        key: K.habitCard(widget.habit.id),
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        child: InkWell(
          onTap: () => _openDetail(context),
          borderRadius: AppRadius.borderM,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // ── Checkbox ──
                PressableScale(
                  child: CheckCircle(
                    key: K.habitCheck(widget.habit.id),
                    isDone: isDone,
                    isSkip: status == LogStatus.skip,
                    onTap: () => _applyStatus(LogStatus.done),
                  ),
                ),
                const SizedBox(width: 12),
                // ── Content ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habitCardTitle(widget.habit, today),
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: isDone
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.45,
                                )
                              : null,
                        ),
                      ),
                      if (widget.habit.isFocus)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: context.palette.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Фокус',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.palette.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Frequency badge (weekdays / x-per-week / every-x-days)
                      if (habitShowsFrequencyBadge(widget.habit))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            frequencyLabel(widget.habit),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // ── Habit icon ──
                HabitIconBadge(icon: widget.habit.icon),
              ],
            ),
          ),
        ),
      ),
    );

    // Undo pill overlays the card's own corner — the card's height never
    // changes when it appears/disappears.
    Widget body = Stack(
      alignment: Alignment.center,
      children: [
        card,
        if (showUndo)
          Positioned(
            right: 8,
            bottom: 8,
            child: _UndoPill(
              onUndo: _undo,
              visible: showUndo && !AppMotion.mayDisable(context),
              glow: _glow,
            ),
          ),
      ],
    );

    return Dismissible(
      key: K.habitCard(widget.habit.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: context.palette.emerald.withValues(alpha: 0.18),
        child: Icon(Icons.check_rounded, color: context.palette.emerald),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: context.palette.greyBlue.withValues(alpha: 0.18),
        child: Icon(Icons.pause_rounded, color: context.palette.greyBlue),
      ),
      movementDuration: const Duration(milliseconds: 220),
      resizeDuration: const Duration(milliseconds: 220),
      dismissThresholds: const {DismissDirection.horizontal: 0.35},
      confirmDismiss: (direction) async {
        final target = direction == DismissDirection.startToEnd
            ? LogStatus.done
            : LogStatus.skip;
        await _applyStatus(target);
        return false; // snap back; the card itself shows the undo action
      },
      child: _GlowShell(
        glow: _glow,
        showGlow: showUndo && !AppMotion.mayDisable(context),
        child: body,
      ),
    );
  }

  void _openDetail(BuildContext context) {
    context.push('/habit/${widget.habit.id}');
  }
}

/// A soft pulsing shell around the card while the undo window is open.
/// Paint-only: box shadow + border, no layout or transform — cheap to run
/// per card and invisible under reduced motion.
class _GlowShell extends StatelessWidget {
  const _GlowShell({
    required this.glow,
    required this.showGlow,
    required this.child,
  });

  final Animation<double> glow;
  final bool showGlow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!showGlow) return child;
    return AnimatedBuilder(
      animation: glow,
      builder: (context, child) {
        final v = glow.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.borderM,
            boxShadow: [
              BoxShadow(
                color: context.palette.emerald.withValues(
                  alpha: 0.10 + v * 0.22,
                ),
                blurRadius: 12 + v * 14,
                spreadRadius: v * 3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// The «Отменить» action as a thick pill overlaying the card's corner —
/// a large, independent tap zone that never depends on the card's height.
/// The emerald→sage gradient is animated: it slowly brightens and shifts its
/// axis while the undo window is open (the same pulse as the outer glow),
/// so the pill itself feels alive. Reduced motion shows the static gradient
/// without the entrance transform or the pulse.
class _UndoPill extends StatelessWidget {
  const _UndoPill({
    required this.onUndo,
    required this.visible,
    required this.glow,
  });

  final VoidCallback onUndo;
  final bool visible;
  final Animation<double> glow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget pill(BoxDecoration decoration) => Material(
      color: Colors.transparent,
      borderRadius: AppRadius.borderM,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: AppRadius.borderM,
          onTap: onUndo,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.undo_rounded, size: 18, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'Отменить',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    BoxDecoration decorationFor(double v) {
      final emerald = context.palette.emerald;
      final sage = context.palette.sage;
      // Slow brighten + axis shift while the window pulses (0..1).
      return BoxDecoration(
        borderRadius: AppRadius.borderM,
        gradient: LinearGradient(
          begin: Alignment(-0.6 - 0.4 * v, -0.8 + 0.3 * v),
          end: Alignment(0.7 + 0.3 * v, 0.8 - 0.3 * v),
          colors: [
            Color.lerp(emerald, Colors.white, v * 0.18)!,
            Color.lerp(sage, Colors.white, v * 0.18)!,
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: context.palette.emerald.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    if (!visible) {
      // Reduced motion: plain flat pill — no gradient, no entrance transform,
      // no pulse (animations are off, so nothing should look "animated").
      return Material(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderM,
        child: InkWell(
          borderRadius: AppRadius.borderM,
          onTap: onUndo,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.undo_rounded,
                  size: 18,
                  color: context.palette.emerald,
                ),
                const SizedBox(width: 6),
                Text(
                  'Отменить',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: context.palette.emerald,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final animated = AnimatedBuilder(
      animation: glow,
      builder: (context, _) => pill(decorationFor(glow.value)),
    );
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.quick, // 150 ms
      curve: AppMotion.easeOutStrong, // cubic(0.23, 1, 0.32, 1)
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
      ),
      child: animated,
    );
  }
}

