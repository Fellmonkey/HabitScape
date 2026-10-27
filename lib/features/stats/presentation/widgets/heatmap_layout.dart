import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One geometry authority for the heatmap: the painter, the hit-test and
/// the scroll-size math all derive from this object instead of re-deriving
/// the same constants in three places.
class HeatmapLayout {
  const HeatmapLayout({
    this.cellSize = 12,
    this.gap = 3,
    this.labelWidth = 18,
    this.monthLabelHeight = 14,
    this.labelGap = 2,
  });

  final double cellSize;
  final double gap;
  final double labelWidth;
  final double monthLabelHeight;
  final double labelGap;

  /// One week column or one weekday row, including the gap.
  double get stride => cellSize + gap;

  /// Top-left of the cell at [week] × [dow] (0 = Monday).
  Offset cellOffset(int week, int dow) => Offset(
    labelWidth + week * stride,
    monthLabelHeight + labelGap + dow * stride,
  );

  /// Week column hit by [dx], or null when the tap lands in the label gutter.
  int? weekHit(double dx) {
    final week = ((dx - labelWidth) / stride).floor();
    return week < 0 ? null : week;
  }

  /// Weekday row hit by [dy], or null outside the 7 rows.
  int? dowHit(double dy) {
    final dow = ((dy - monthLabelHeight - labelGap) / stride).floor();
    return (dow < 0 || dow > 6) ? null : dow;
  }

  /// Full canvas size for [weekCount] week columns.
  Size sizeFor(int weekCount) => Size(
    labelWidth + weekCount * stride,
    monthLabelHeight + labelGap + 7 * stride,
  );
}

/// One heatmap intensity step: the completion-ratio band it covers and the
/// alpha of the fill it uses on its base colour.
class HeatmapIntensityStep {
  const HeatmapIntensityStep({required this.upTo, required this.alpha});

  /// Upper bound of the ratio band. Inclusive for the first (empty) step,
  /// exclusive for every later step.
  final double upTo;

  /// Fill alpha used by this step (1.0 switches to the full glow).
  final double alpha;
}

/// The five heatmap intensity tiers — the single source for both the painter
/// and the legend, so they can never disagree about how many steps exist or
/// where one band ends and the next begins.
const heatmapIntensityTiers = <HeatmapIntensityStep>[
  HeatmapIntensityStep(upTo: 0.0, alpha: 0.08),
  HeatmapIntensityStep(upTo: 0.25, alpha: 0.35),
  HeatmapIntensityStep(upTo: 0.5, alpha: 0.6),
  HeatmapIntensityStep(upTo: 0.75, alpha: 0.85),
  HeatmapIntensityStep(upTo: 1.0, alpha: 1.0),
];

/// Cell color for a day's completion [ratio] — derived from the single tier
/// list, so the painter can never disagree with the legend about how many
/// steps exist. The empty tier paints [onSurface] faintly; the top tier
/// switches to the full glow; everything in between tints sage green.
Color heatmapCellColor(double ratio, {required Color onSurface}) {
  var tierIndex = 0;
  while (tierIndex < heatmapIntensityTiers.length - 1) {
    final step = heatmapIntensityTiers[tierIndex];
    final occupies = tierIndex == 0 ? ratio <= step.upTo : ratio < step.upTo;
    if (occupies) break;
    tierIndex++;
  }
  return heatmapTierFill(tierIndex, onSurface: onSurface);
}

/// The fill for one tier index — shared by the painter and the legend, so a
/// legend swatch can never disagree with the painted cell.
Color heatmapTierFill(int tierIndex, {required Color onSurface}) {
  final alpha = heatmapIntensityTiers[tierIndex].alpha;
  if (tierIndex == 0) return onSurface.withValues(alpha: alpha);
  if (tierIndex == heatmapIntensityTiers.length - 1) {
    return AppColors.emeraldGlow;
  }
  return AppColors.sageGreen.withValues(alpha: alpha);
}
