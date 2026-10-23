import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/motion_tokens.dart';

/// Today's completion ring in the greenhouse header. Pulses when today's
/// completion grows — feedback, not decoration.
class ProgressRing extends StatefulWidget {
  const ProgressRing({super.key, required this.progress});

  final double progress;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
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
  void didUpdateWidget(covariant ProgressRing oldWidget) {
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
