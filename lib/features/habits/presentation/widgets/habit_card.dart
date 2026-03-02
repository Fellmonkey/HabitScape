import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/habit_providers.dart';

/// A single habit row in the Greenhouse list.
/// - Checkbox on the left for instant marking.
/// - Tap body → detail bottom sheet.
/// - Long press → mark done (alt).
/// - Swipe left → Skip / Fail / Delete menu.
class HabitCard extends ConsumerStatefulWidget {
  const HabitCard({
    required this.habit,
    required this.log,
    super.key,
  });

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
      widget.log != null && widget.log!.status == LogStatus.done.name;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    if (_isDone) return;
    HapticFeedback.mediumImpact();
    _bounceController.forward(from: 0);
    ref.read(habitActionsProvider.notifier).markDone(widget.habit.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final status = widget.log != null
        ? LogStatus.fromString(widget.log!.status)
        : null;

    return Dismissible(
      key: ValueKey('habit_${widget.habit.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _showSwipeMenu(context),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // ── Checkbox ──
                    _CheckCircle(
                      key: K.habitCheck(widget.habit.id),
                      isDone: _isDone,
                      isSkip: status == LogStatus.skip,
                      isFail: status == LogStatus.fail,
                      onTap: _markDone,
                    ),
                    const SizedBox(width: 12),
                    // ── Content ──
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.habit.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration:
                                  _isDone ? TextDecoration.lineThrough : null,
                              color: _isDone
                                  ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
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
                        ],
                      ),
                    ),
                    // ── Seed archetype icon ──
                    _SeedIcon(archetype: widget.habit.seedArchetype),
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

  Future<bool?> _showSwipeMenu(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: K.swipeSkip,
              leading: const Icon(Icons.pause_circle_outline,
                  color: AppColors.coolGreyBlue),
              title: const Text('Уважительный пропуск'),
              onTap: () => Navigator.pop(ctx, 'skip'),
            ),
            ListTile(
              key: K.swipeFail,
              leading: const Icon(Icons.close, color: AppColors.dustyRose),
              title: const Text('Срыв'),
              onTap: () => Navigator.pop(ctx, 'fail'),
            ),
            ListTile(
              key: K.swipeDelete,
              leading: const Icon(Icons.delete_outline, color: AppColors.fadedPlum),
              title: const Text('Удалить'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return false;

    final actions = ref.read(habitActionsProvider.notifier);
    switch (result) {
      case 'skip':
        await actions.markSkip(widget.habit.id);
      case 'fail':
        await actions.markFail(widget.habit.id);
      case 'delete':
        await actions.deleteHabit(widget.habit.id);
    }
    return false; // Don't dismiss the Dismissible itself
  }

  void _openDetail(BuildContext context) {
    context.push('/habit/${widget.habit.id}');
  }
}

/// Circular check indicator with color-coded states.
class _CheckCircle extends StatelessWidget {
  const _CheckCircle({
    super.key,
    required this.isDone,
    required this.isSkip,
    required this.isFail,
    required this.onTap,
  });

  final bool isDone;
  final bool isSkip;
  final bool isFail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color? fillColor;
    IconData? icon;

    if (isDone) {
      borderColor = AppColors.emeraldGlow;
      fillColor = AppColors.emeraldGlow;
      icon = Icons.check_rounded;
    } else if (isSkip) {
      borderColor = AppColors.coolGreyBlue;
      fillColor = AppColors.coolGreyBlue.withValues(alpha: 0.3);
      icon = Icons.pause_rounded;
    } else if (isFail) {
      borderColor = AppColors.dustyRose;
      fillColor = AppColors.dustyRose.withValues(alpha: 0.3);
      icon = Icons.close_rounded;
    } else {
      borderColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);
      fillColor = null;
      icon = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
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
    );
  }
}

/// Small icon representing the seed archetype.
class _SeedIcon extends StatelessWidget {
  const _SeedIcon({required this.archetype});

  final String archetype;

  @override
  Widget build(BuildContext context) {
    final type = SeedArchetype.fromString(archetype);
    final IconData icon = switch (type) {
      SeedArchetype.oak => Icons.park_rounded,
      SeedArchetype.sakura => Icons.filter_vintage_rounded,
      SeedArchetype.pine => Icons.nature_rounded,
      SeedArchetype.willow => Icons.grass_rounded,
      SeedArchetype.baobab => Icons.forest_rounded,
      SeedArchetype.palm => Icons.beach_access_rounded,
    };

    return Icon(
      icon,
      size: 20,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
    );
  }
}
