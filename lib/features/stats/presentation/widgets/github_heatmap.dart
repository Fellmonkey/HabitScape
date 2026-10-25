import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/calendar_grid.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../core/domain/completion.dart';

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
  return _tierFill(tierIndex, onSurface: onSurface);
}

Color _tierFill(int tierIndex, {required Color onSurface}) {
  final alpha = heatmapIntensityTiers[tierIndex].alpha;
  if (tierIndex == 0) return onSurface.withValues(alpha: alpha);
  if (tierIndex == heatmapIntensityTiers.length - 1) {
    return AppColors.emeraldGlow;
  }
  return AppColors.sageGreen.withValues(alpha: alpha);
}

/// GitHub-style heatmap: 7 weekday rows × N week columns, each cell colored
/// by the day's completion ratio. One [CustomPainter] paints the whole grid
/// instead of ~380 individual widgets (layout cost on low-end devices).
class GithubHeatmap extends StatefulWidget {
  const GithubHeatmap({
    required this.days,
    this.cellSize = 12,
    this.gap = 3,
    this.onDayTap,
    super.key,
  });

  /// Last 365 days, oldest first.
  final List<DayCompletion> days;
  final double cellSize;
  final double gap;
  final ValueChanged<DayCompletion>? onDayTap;

  @override
  State<GithubHeatmap> createState() => _GithubHeatmapState();
}

class _GithubHeatmapState extends State<GithubHeatmap> {
  /// Built during the first layout — the viewport width is known then, so the
  /// view opens on the most recent weeks instead of a year-old January.
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final cellSize = widget.cellSize;
    final gap = widget.gap;
    final theme = Theme.of(context);
    final first = days.first.date;
    final last = days.last.date;
    final grid = CalendarGrid.range(first: first, last: last, today: last);
    final weekCount = grid.weeks.length;

    // One geometry authority: the painter, the hit-test below and the
    // scroll math all derive from the same layout.
    final layout = HeatmapLayout(cellSize: cellSize, gap: gap);
    final totalSize = layout.sizeFor(weekCount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.maxWidth;
        final endOffset = viewport.isFinite && viewport < totalSize.width
            ? totalSize.width - viewport
            : 0.0;
        final controller = _controller ??= ScrollController(
          initialScrollOffset: endOffset,
        );

        return SingleChildScrollView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          child: GestureDetector(
            onTapDown: (details) {
              final cb = widget.onDayTap;
              if (cb == null) return;
              final week = layout.weekHit(details.localPosition.dx);
              final dow = layout.dowHit(details.localPosition.dy);
              if (week == null || dow == null) return;
              final date = grid.start.add(Duration(days: week * 7 + dow));
              for (final d in days) {
                if (d.date == date) {
                  cb(d);
                  return;
                }
              }
            },
            child: CustomPaint(
              size: totalSize,
              painter: _HeatmapPainter(
                days: days,
                grid: grid,
                layout: layout,
                weekdayLabelStyle: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                ),
                monthLabelStyle: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                ),
                onSurface: theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.days,
    required this.grid,
    required this.layout,
    required this.weekdayLabelStyle,
    required this.monthLabelStyle,
    required this.onSurface,
  });

  final List<DayCompletion> days;
  final CalendarGrid grid;
  final HeatmapLayout layout;
  final TextStyle? weekdayLabelStyle;
  final TextStyle? monthLabelStyle;
  final Color onSurface;

  late final Map<DateTime, DayCompletion> _dayByDate = {
    for (final d in days) d.date: d,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // ── Month labels ──────────────────────────────────────────
    for (var week = 0; week < grid.weeks.length; week++) {
      String? label;
      for (final cell in grid.weeks[week]) {
        if (cell == null) continue;
        if (cell.date.day == 1) {
          label = monthNames[cell.date.month].substring(0, 3);
          break;
        }
      }
      if (label == null) continue;
      textPainter.text = TextSpan(text: label, style: monthLabelStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(layout.cellOffset(week, 0).dx, 0));
    }

    // ── Weekday labels ────────────────────────────────────────
    for (var dow = 0; dow < 7; dow++) {
      final label = switch (dow) {
        0 => 'Пн',
        2 => 'Ср',
        4 => 'Пт',
        _ => '',
      };
      if (label.isEmpty) continue;
      textPainter.text = TextSpan(text: label, style: weekdayLabelStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, layout.cellOffset(0, dow).dy));
    }

    // ── Cells ─────────────────────────────────────────────────
    final paint = Paint();
    for (var week = 0; week < grid.weeks.length; week++) {
      for (var dow = 0; dow < 7; dow++) {
        final cell = grid.weeks[week][dow];
        if (cell == null) continue;
        final comp = _dayByDate[cell.date];
        if (comp == null) continue;
        paint.color = heatmapCellColor(comp.ratio, onSurface: onSurface);
        final origin = layout.cellOffset(week, dow);
        final rect = Rect.fromLTWH(
          origin.dx,
          origin.dy,
          layout.cellSize,
          layout.cellSize,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) {
    return !identical(oldDelegate.days, days) ||
        !identical(oldDelegate.grid, grid) ||
        !identical(oldDelegate.layout, layout) ||
        oldDelegate.onSurface != onSurface ||
        oldDelegate.weekdayLabelStyle != weekdayLabelStyle ||
        oldDelegate.monthLabelStyle != monthLabelStyle;
  }
}

/// Small legend for the heatmap ("Less → More").
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Меньше', style: theme.textTheme.labelSmall),
        const SizedBox(width: 6),
        for (var i = 0; i < heatmapIntensityTiers.length; i++) ...[
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: _tierFill(i, onSurface: theme.colorScheme.onSurface),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text('Больше', style: theme.textTheme.labelSmall),
      ],
    );
  }
}
