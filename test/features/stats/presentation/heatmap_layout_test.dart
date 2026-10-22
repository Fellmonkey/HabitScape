import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/theme/app_colors.dart';
import 'package:rythm/features/stats/presentation/widgets/github_heatmap.dart';

void main() {
  group('HeatmapLayout', () {
    const layout = HeatmapLayout();

    test('cellOffset and hit-testing agree on every cell', () {
      for (var week = 0; week < 20; week++) {
        for (var dow = 0; dow < 7; dow++) {
          final offset = layout.cellOffset(week, dow);
          expect(layout.weekHit(offset.dx), week);
          expect(layout.dowHit(offset.dy), dow);
        }
      }
    });

    test('hit-testing rejects the label gutter and out-of-grid taps', () {
      expect(layout.weekHit(layout.labelWidth - 1), isNull);
      expect(
        layout.dowHit(layout.monthLabelHeight + layout.labelGap - 1),
        isNull,
      );
      expect(layout.dowHit(layout.cellOffset(0, 6).dy + layout.stride), isNull);
    });

    test('sizeFor matches the cell math', () {
      const weeks = 12;
      final size = layout.sizeFor(weeks);
      expect(size.width, layout.labelWidth + weeks * layout.stride);
      expect(
        size.height,
        layout.monthLabelHeight + layout.labelGap + 7 * layout.stride,
      );
    });

    test('heatmapIntensityTiers is the shared five-step scale', () {
      expect(heatmapIntensityTiers, [0.08, 0.35, 0.6, 0.85, 1.0]);
    });
  });

  group('heatmapCellColor', () {
    const onSurface = Colors.black;

    test('thresholds map to the five tiers', () {
      expect(
        heatmapCellColor(0.0, onSurface: onSurface),
        onSurface.withValues(alpha: 0.08),
      );
      expect(
        heatmapCellColor(0.2, onSurface: onSurface),
        AppColors.sageGreen.withValues(alpha: 0.35),
      );
      expect(
        heatmapCellColor(0.4, onSurface: onSurface),
        AppColors.sageGreen.withValues(alpha: 0.6),
      );
      expect(
        heatmapCellColor(0.7, onSurface: onSurface),
        AppColors.sageGreen.withValues(alpha: 0.85),
      );
      expect(
        heatmapCellColor(1.0, onSurface: onSurface),
        AppColors.emeraldGlow,
      );
    });
  });
}
