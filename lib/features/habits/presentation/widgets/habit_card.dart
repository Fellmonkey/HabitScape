import 'dart:async';

import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../core/domain/scheduling.dart';
import '../../../../core/settings/today.dart';
import '../../providers/habit_actions.dart';
import '../../providers/habit_streams.dart';

/// How long a completion/skip stays undoable on the card.
const habitUndoWindow = Duration(seconds: 5);

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

  /// The habit's log status for today, refreshed live from the logs stream
  /// (not just from the pinned [HabitCard.log] prop). The animated list keeps
  /// row widgets alive even when their data changes, so the card has to
  /// observe the stream itself — otherwise a completed habit only *looks*
  /// done after the list fully rebuilds (e.g. after switching tabs).
  LogStatus? _liveStatus;

  /// Optimistic done: set the moment the user taps, so the check fills in
  /// immediately. Cleared if the database write fails.
  bool _optimisticDone = false;

  /// Undo window state: [._undoOpen] marks the open window; [_undoPrevious]
  /// is the status that existed before the last change (null = no log).
  bool _undoOpen = false;
  LogStatus? _undoPrevious;
  Timer? _undoTimer;

  /// Soft pulsing glow while the undo window is open — previews that the
  /// card is about to leave the board (hide-completed view). Paint-only
  /// (box shadow / border), disabled under reduced motion.
  late final AnimationController _glowController;
  late final Animation<double> _glow;

  bool get _isDone => _liveStatus == LogStatus.done || _optimisticDone;

  bool get _showUndo => _undoOpen;

  bool get _showFreqBadge {
    final type = FrequencyType.fromString(widget.habit.frequencyType);
    return type == FrequencyType.weekdays ||
        type == FrequencyType.xPerWeek ||
        type == FrequencyType.everyXDays ||
        type == FrequencyType.cycle;
  }

  String _buildTitle(DateTime today) {
    final name = widget.habit.name;
    final type = FrequencyType.fromString(widget.habit.frequencyType);
    if (type != FrequencyType.cycle) return name;

    final label = getCycleLabelForDate(widget.habit, today); // "today" view
    if (label != null && label.isNotEmpty) {
      return '$name: $label';
    }
    return name;
  }

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
    _undoTimer?.cancel();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Applies [status] (done / skip) and opens the undo window with the
  /// pre-change status. Shared by the check-circle tap and the swipe.
  Future<void> _applyStatus(LogStatus status) async {
    final previous = _liveStatus;
    if (previous == status) return;

    if (status == LogStatus.done) {
      Haptics.medium(ref.read(hapticsEnabledProvider));
      if (!AppMotion.mayDisable(context)) {
        _bounceController.forward(from: 0);
      }
    } else {
      Haptics.tap(ref.read(hapticsEnabledProvider));
    }

    // Show the completed state immediately; confirm (or roll back) once the
    // write round-trips through the database stream.
    setState(() => _optimisticDone = status == LogStatus.done);
    _openUndoWindow(previous);

    try {
      await ref.read(habitActionsProvider.notifier).logToday([
        widget.habit.id,
      ], status: status);
      widget.onStatusChanged?.call();
    } catch (_) {
      if (mounted) {
        _cancelUndoWindow();
        setState(() => _optimisticDone = false);
      }
    }
  }

  void _openUndoWindow(LogStatus? previous) {
    _undoTimer?.cancel();
    setState(() {
      _undoOpen = true;
      _undoPrevious = previous;
    });
    if (!AppMotion.mayDisable(context) && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    }
    _undoTimer = Timer(habitUndoWindow, () {
      if (!mounted) return;
      _cancelUndoWindow();
    });
  }

  void _cancelUndoWindow() {
    _undoTimer?.cancel();
    _undoTimer = null;
    _glowController.stop();
    _glowController.value = 0;
    if (mounted) {
      setState(() {
        _undoOpen = false;
        _undoPrevious = null;
      });
    }
  }

  Future<void> _undo() async {
    final previous = _undoPrevious;
    _cancelUndoWindow();
    setState(() => _optimisticDone = false);
    try {
      await ref
          .read(habitActionsProvider.notifier)
          .undoTodayLog(widget.habit.id, previous: previous);
    } catch (_) {
      // The stream will settle on whatever state survived the failed write.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Keep the visible status in sync with the live logs stream. The board
    // list may keep this row alive with a stale log prop, so the source of
    // truth for "is it done" is the stream, not the prop.
    final todayLogs = ref.watch(todayLogsProvider).value ?? const <HabitLog>[];
    _liveStatus =
        todayLogs
            .where((l) => l.habitId == widget.habit.id)
            .firstOrNull
            ?.status ??
        widget.log?.status;
    final status = _liveStatus;
    final today = ref.watch(todayDateProvider);

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
                  child: _CheckCircle(
                    key: K.habitCheck(widget.habit.id),
                    isDone: _isDone,
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
                        _buildTitle(today),
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: _isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: _isDone
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
                      if (_showFreqBadge)
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
                _HabitIcon(icon: widget.habit.icon),
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
        if (_showUndo)
          Positioned(
            right: 8,
            bottom: 8,
            child: _UndoPill(
              onUndo: _undo,
              visible: _showUndo && !AppMotion.mayDisable(context),
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
        showGlow: _showUndo && !AppMotion.mayDisable(context),
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

/// Circular check indicator with color-coded states and a water-drop
/// ripple burst on tap. The visible circle stays 28 px; the hit area is the
/// standard 44 px so daily taps don't miss.
class _CheckCircle extends StatefulWidget {
  const _CheckCircle({
    super.key,
    required this.isDone,
    required this.isSkip,
    required this.onTap,
  });

  final bool isDone;
  final bool isSkip;
  final VoidCallback onTap;

  @override
  State<_CheckCircle> createState() => _CheckCircleState();
}

class _CheckCircleState extends State<_CheckCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dropController;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _dropController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _ringScale = Tween(begin: 0.6, end: 2.4).animate(
      CurvedAnimation(parent: _dropController, curve: AppMotion.easeOutStrong),
    );
    _ringOpacity = Tween(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _dropController, curve: AppMotion.easeOutStrong),
    );
  }

  @override
  void dispose() {
    _dropController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // The ring is feedback for a real change — tapping an already-done check
    // only re-fires nothing. Reduced-motion users skip the expanding ring.
    if (!widget.isDone && !AppMotion.mayDisable(context)) {
      _dropController.forward(from: 0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color? fillColor;
    IconData? icon;

    if (widget.isDone) {
      borderColor = context.palette.emerald;
      fillColor = context.palette.emerald;
      icon = Icons.check_rounded;
    } else if (widget.isSkip) {
      borderColor = context.palette.greyBlue;
      fillColor = context.palette.greyBlue.withValues(alpha: 0.3);
      icon = Icons.pause_rounded;
    } else {
      borderColor = Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.25);
      fillColor = null;
      icon = null;
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  // expanding water-drop ripple ring
                  animation: _dropController,
                  builder: (context, child) {
                    return Container(
                      width: 28 * _ringScale.value,
                      height: 28 * _ringScale.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.palette.emerald.withValues(
                            alpha: _ringOpacity.value,
                          ),
                          width: 2.5,
                        ),
                      ),
                    );
                  },
                ),
                AnimatedContainer(
                  // the check circle itself
                  duration: AppMotion.base,
                  curve: AppMotion.easeOutStrong,
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fillColor,
                    border: fillColor == null
                        ? Border.all(color: borderColor, width: 2)
                        : null,
                  ),
                  child: icon != null
                      ? Icon(icon, size: 18, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small icon representing the habit.
class _HabitIcon extends StatelessWidget {
  const _HabitIcon({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    final type = HabitIcon.fromString(icon);

    return Icon(
      type.visual.icon,
      size: 20,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
    );
  }
}
