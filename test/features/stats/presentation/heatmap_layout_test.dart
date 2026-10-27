import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/theme/app_colors.dart';
import 'package:rythm/features/stats/presentation/widgets/heatmap_layout.dart';

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
      expect(heatmapIntensityTiers, hasLength(5));
      expect(heatmapIntensityTiers.map((s) => s.alpha), [
        0.08,
        0.35,
        0.6,
        0.85,
        1.0,
      ]);
      expect(heatmapIntensityTiers.map((s) => s.upTo), [
        0.0,
        0.25,
        0.5,
        0.75,
        1.0,
      ]);
    });
  });

  group('heatmapCellColor', () {
    const onSurface = Colors.black;
    const doneColor = AppColors.emeraldGlow;
    const sageColor = AppColors.sageGreen;

    test('thresholds map to the five tiers', () {
      expect(
        heatmapCellColor(
          0.0,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        onSurface.withValues(alpha: 0.08),
      );
      expect(
        heatmapCellColor(
          0.2,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        AppColors.sageGreen.withValues(alpha: 0.35),
      );
      expect(
        heatmapCellColor(
          0.4,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        AppColors.sageGreen.withValues(alpha: 0.6),
      );
      expect(
        heatmapCellColor(
          0.7,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        AppColors.sageGreen.withValues(alpha: 0.85),
      );
      expect(
        heatmapCellColor(
          1.0,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        AppColors.emeraldGlow,
      );
    });

    test('band boundaries land on the next tier, not the previous one', () {
      expect(
        heatmapCellColor(
          0.25,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        AppColors.sageGreen.withValues(alpha: 0.6),
      );
      expect(
        heatmapCellColor(
          0.5,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        AppColors.sageGreen.withValues(alpha: 0.85),
      );
      expect(
        heatmapCellColor(
          0.75,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        AppColors.emeraldGlow,
      );
      expect(
        heatmapCellColor(
          0.1,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        AppColors.sageGreen.withValues(alpha: 0.35),
      );
    });

    test('negative ratios read as empty (first tier)', () {
      expect(
        heatmapCellColor(
          -0.5,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        ),
        onSurface.withValues(alpha: 0.08),
      );
    });
  });
}
