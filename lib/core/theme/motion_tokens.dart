import 'package:flutter/material.dart';

/// Motion tokens — single source of truth for durations and curves.
/// Values follow the animation bar: UI under 300ms, strong custom curves,
/// `transform`/`opacity` only.
abstract final class AppMotion {
  // ── Durations ───────────────────────────────────────────────
  /// Button/tap press feedback (100–160ms budget).
  static const Duration press = Duration(milliseconds: 120);

  /// Color/selection changes.
  static const Duration quick = Duration(milliseconds: 150);

  /// Small state changes.
  static const Duration base = Duration(milliseconds: 200);

  /// Delight / fanfare (rare moments only).
  static const Duration slow = Duration(milliseconds: 280);

  /// On-screen travel (month switch, route transitions).
  static const Duration travel = Duration(milliseconds: 260);

  // ── Curves ──────────────────────────────────────────────────
  /// Strong ease-out (fast start, settled end) — entrances and feedback.
  static const Curve easeOutStrong = Cubic(0.23, 1.0, 0.32, 1.0);

  /// Strong ease-in-out — on-screen movement/morphing.
  static const Curve easeInOutStrong = Cubic(0.77, 0.0, 0.175, 1.0);

  /// True when the OS asks for reduced motion. Decorative motion (position,
  /// scale, movement) should be dropped in that case; opacity/color feedback
  /// and haptics stay.
  static bool mayDisable(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}
