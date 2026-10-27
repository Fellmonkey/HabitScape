import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Glassmorphism card: semi-transparent, backdrop-blurred container for
/// overlays, analytics cards and bottom sheets.
///
/// The blur clip and the inner [Material] share [borderRadius], so ink
/// ripples from [ListTile]s and buttons never bleed past the rounded corner.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppRadius.borderL,
    this.sigmaX = 12,
    this.sigmaY = 12,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final double sigmaX;
  final double sigmaY;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: borderRadius,
            border: Border.all(
              color: isDark
                  ? AppColors.glassBorderDark
                  : AppColors.glassBorderLight,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.warmAmber.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          // Material ancestor so ListTile children paint their ink here, and
          // the ink is clipped to the same radius as the card.
          child: Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}
