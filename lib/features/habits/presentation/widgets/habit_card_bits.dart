import 'package:flutter/material.dart' hide TimeOfDay;

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';

/// Circular check indicator with color-coded states and a water-drop ripple
/// burst on tap. The visible circle stays 28 px; the hit area is the
/// standard 44 px so daily taps don't miss.
class CheckCircle extends StatefulWidget {
  const CheckCircle({
    super.key,
    required this.isDone,
    required this.isSkip,
    required this.onTap,
  });

  final bool isDone;
  final bool isSkip;
  final VoidCallback onTap;

  @override
  State<CheckCircle> createState() => _CheckCircleState();
}

class _CheckCircleState extends State<CheckCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dropController;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _dropController = AnimationController(vsync: this, duration: AppMotion.slow);
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
class HabitIconBadge extends StatelessWidget {
  const HabitIconBadge({super.key, required this.icon});

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
