import 'package:flutter/material.dart' hide TimeOfDay;

import '../../../../core/domain/completion.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../core/utils/calendar_grid.dart';
import '../../../../core/utils/localized_dates.dart';
import 'heatmap_layout.dart';

/// GitHub-style heatmap: 7 weekday rows × N week columns, each cell colored
/// by the day's completion ratio. One [CustomPainter] paints the whole grid
/// instead of ~380 individual widgets (layout cost on low-end devices).
class GithubHeatmap extends StatefulWidget {
  const GithubHeatmap({
    required this.days,
    this.today,
    this.cellSize = 14,
    this.gap = 2,
    this.onDayTap,
    super.key,
  });

  /// Last 365 days, oldest first.
  final List<DayCompletion> days;

  /// The day that gets the "today" marker on the grid.
  final DateTime? today;
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
  bool _didTravel = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.days;
    if (days.isEmpty) {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Пока нет данных за год — отмечай привычки, и здесь появится карта активности.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      );
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
        final controller = _controller ??= ScrollController();
        if (!_didTravel) {
          _didTravel = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !controller.hasClients) return;
            if (endOffset > 0 && !AppMotion.mayDisable(context)) {
              controller.animateTo(
                endOffset,
                duration: AppMotion.travel,
                curve: AppMotion.easeOutStrong,
              );
            } else {
              controller.jumpTo(endOffset);
            }
          });
        }

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
                today: widget.today,
                todayColor: theme.colorScheme.primary,
                doneColor: context.palette.emerald,
                sageColor: context.palette.sage,
                weekdayLabelStyle: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                ),
                monthLabelStyle: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
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
    required this.today,
    required this.todayColor,
    required this.doneColor,
    required this.sageColor,
    required this.weekdayLabelStyle,
    required this.monthLabelStyle,
    required this.onSurface,
  });

  final List<DayCompletion> days;
  final CalendarGrid grid;
  final HeatmapLayout layout;
  final DateTime? today;
  final Color todayColor;
  final Color doneColor;
  final Color sageColor;
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
    final today = this.today;
    for (var week = 0; week < grid.weeks.length; week++) {
      for (var dow = 0; dow < 7; dow++) {
        final cell = grid.weeks[week][dow];
        if (cell == null) continue;
        final comp = _dayByDate[cell.date];
        if (comp == null) continue;
        paint.color = heatmapCellColor(
          comp.ratio,
          onSurface: onSurface,
          doneColor: doneColor,
          sageColor: sageColor,
        );
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

        // ── "Today" marker ─────────────────────────────────────
        if (today != null && cell.date == today) {
          final marker = Rect.fromLTWH(
            origin.dx - 1.5,
            origin.dy - 1.5,
            layout.cellSize + 3,
            layout.cellSize + 3,
          );
          final borderPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = todayColor;
          canvas.drawRRect(
            RRect.fromRectAndRadius(marker, const Radius.circular(4)),
            borderPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) {
    return !identical(oldDelegate.days, days) ||
        !identical(oldDelegate.grid, grid) ||
        !identical(oldDelegate.layout, layout) ||
        oldDelegate.onSurface != onSurface ||
        oldDelegate.doneColor != doneColor ||
        oldDelegate.sageColor != sageColor ||
        oldDelegate.weekdayLabelStyle != weekdayLabelStyle ||
        oldDelegate.monthLabelStyle != monthLabelStyle ||
        oldDelegate.today != today ||
        oldDelegate.todayColor != todayColor;
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
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: heatmapTierFill(
                i,
                onSurface: theme.colorScheme.onSurface,
                doneColor: context.palette.emerald,
                sageColor: context.palette.sage,
              ),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text('Больше', style: theme.textTheme.labelSmall),
      ],
    );
  }
}
