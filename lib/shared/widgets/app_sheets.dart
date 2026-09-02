import 'package:flutter/material.dart';

import '../../core/theme/motion_tokens.dart';

/// Shared bottom-sheet helper — one uniform entrance/exit across the app.
///
/// Uses the system sheet slide with the app's strong ease-out curve, a
/// 280ms entrance and a snappier 150ms exit (the system responds faster than
/// the user's deliberate action).
abstract final class AppSheets {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    Color backgroundColor = Colors.transparent,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      sheetAnimationStyle: AnimationStyle(
        curve: AppMotion.easeOutStrong,
        reverseCurve: AppMotion.easeOutStrong,
        duration: AppMotion.slow,
        reverseDuration: AppMotion.quick,
      ),
      builder: builder,
    );
  }
}
