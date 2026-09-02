import 'package:flutter/material.dart';

import '../../core/theme/motion_tokens.dart';

/// Wraps a pressable so it squashes subtly on tap-down (0.97) and springs
/// back on release — press feedback for buttons that don't already have one.
/// `transform`-only, reduced-motion safe (it becomes a no-op).
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
  });

  final Widget child;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.mayDisable(context)) return widget.child;

    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: AppMotion.press,
        curve: AppMotion.easeOutStrong,
        child: widget.child,
      ),
    );
  }
}
