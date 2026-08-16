import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../domain/scheduling.dart';
import '../../providers/habit_providers.dart';

/// A single habit row in the Greenhouse list.
/// - Checkbox on the left for instant marking.
/// - Tap body → detail bottom sheet.
/// - Long press → mark done (alt).
/// - Swipe left → Skip / Delete menu.
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

  String _buildTitle() {
    final name = widget.habit.name;
    final type = FrequencyType.fromString(widget.habit.frequencyType);
    if (type != FrequencyType.cycle) return name;

    // We assume the card is showing for "today" (Greenhouse view).
    // If you need exact date, it should be passed from parent, but here we use now.
    final label = getCycleLabelForDate(widget.habit, DateTime.now());
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
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.95), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
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
    _bounceController.forward(from: 0);
    ref.read(habitActionsProvider.notifier).markDone(widget.habit.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = widget.log?.status;

    return Dismissible(
      key: ValueKey('habit_${widget.habit.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showSwipeMenu(),
      background: _buildSwipeBackground(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onLongPress: _markDone,
          child: Card(
            key: K.habitCard(widget.habit.id),
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            child: InkWell(
              onTap: () => _openDetail(context),
              borderRadius: AppRadius.borderM,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // ── Checkbox ──
                    _CheckCircle(
                      key: K.habitCheck(widget.habit.id),
                      isDone: _isDone,
                      isSkip: status == LogStatus.skip,
                      onTap: _markDone,
                    ),
                    const SizedBox(width: 12),
                    // ── Content ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _buildTitle(),
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
        ),
      ),
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.dustyRose.withValues(alpha: 0.2),
        borderRadius: AppRadius.borderM,
      ),
      child: const Icon(Icons.more_horiz, color: AppColors.dustyRose),
    );
  }

  Future<bool?> _showSwipeMenu() async {
    final theme = Theme.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: 8),
              ListTile(
                key: K.swipeSkip,
                leading: const Icon(
                  Icons.pause_circle_outline,
                  color: AppColors.coolGreyBlue,
                ),
                title: const Text('Уважительный пропуск'),
                onTap: () => Navigator.pop(ctx, 'skip'),
              ),
              ListTile(
                key: K.swipeDelete,
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.fadedPlum,
                ),
                title: const Text('Удалить'),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return false;

    final actions = ref.read(habitActionsProvider.notifier);
    switch (result) {
      case 'skip':
        await actions.markSkip(widget.habit.id);
      case 'delete':
        if (!mounted) return false;
        final confirmed = await _confirmDelete(context);
        if (confirmed != true) return false;
        await actions.deleteHabit(widget.habit.id);
    }
    return false; // Don't dismiss the Dismissible itself
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить привычку?'),
        content: Text(
          '«${widget.habit.name}» будет удалена вместе со всей историей. '
          'Это нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    context.push('/habit/${widget.habit.id}');
  }
}

/// Circular check indicator with color-coded states and a water-drop
/// ripple burst when tapped.
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
      duration: const Duration(milliseconds: 450),
    );
    _ringScale = Tween(
      begin: 0.6,
      end: 2.4,
    ).animate(CurvedAnimation(parent: _dropController, curve: Curves.easeOut));
    _ringOpacity = Tween(
      begin: 0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _dropController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _dropController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _dropController.forward(from: 0);
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
            // Expanding water-drop ripple ring.
            AnimatedBuilder(
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
            // The check circle itself.
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
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

/// Small neutral icon representing the habit.
class _HabitIcon extends StatelessWidget {
  const _HabitIcon({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    final type = HabitIcon.fromString(icon);

    return Icon(
      type.icon,
      size: 20,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
    );
  }
}
