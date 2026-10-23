import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/motion_tokens.dart';

/// One-shot entrance for a newly created habit: fade + rise + a water ring
/// bursting near the icon («капля о воду»). Reduced-motion users get the row
/// instantly.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, required this.onComplete});

  final Widget child;
  final VoidCallback onComplete;

  /// Wait for the creating sheet to finish closing (150ms exit + margin) so
  /// the entrance plays on a fully visible screen.
  static const startDelay = Duration(milliseconds: 180);

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
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
      Future<void>.delayed(Entrance.startDelay, () {
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
