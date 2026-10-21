import 'package:flutter/material.dart';
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
import '../../domain/scheduling.dart';
import '../../../../core/settings/today.dart';
import '../../providers/habit_providers.dart';

/// A single habit row in the Greenhouse list: tap the check circle to mark
/// done, tap the card to open details.
class HabitCard extends ConsumerStatefulWidget {
  const HabitCard({required this.habit, required this.log, super.key});

  final Habit habit;
  final HabitLog? log;

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnim;

  bool get _isDone =>
      widget.log != null && widget.log!.status == LogStatus.done;

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
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    if (_isDone) return;
    Haptics.medium(ref.read(hapticsEnabledProvider));
    if (!AppMotion.mayDisable(context)) _bounceController.forward(from: 0);
    ref.read(habitActionsProvider.notifier).logToday([
      widget.habit.id,
    ], status: LogStatus.done);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = widget.log?.status;
    final today = ref.watch(todayDateProvider);

    return ScaleTransition(
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
                    onTap: _markDone,
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
                                color: AppColors.warmAmber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Фокус',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.warmAmber,
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
                                alpha: 0.45,
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
  }

  void _openDetail(BuildContext context) {
    context.push('/habit/${widget.habit.id}');
  }
}

/// Circular check indicator with color-coded states and a water-drop
/// ripple burst on tap.
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
      borderColor = AppColors.emeraldGlow;
      fillColor = AppColors.emeraldGlow;
      icon = Icons.check_rounded;
    } else if (widget.isSkip) {
      borderColor = AppColors.coolGreyBlue;
      fillColor = AppColors.coolGreyBlue.withValues(alpha: 0.3);
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
                      color: AppColors.emeraldGlow.withValues(
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
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
    );
  }
}
