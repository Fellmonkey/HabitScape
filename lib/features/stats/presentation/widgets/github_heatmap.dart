import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../habits/domain/completion.dart';

/// GitHub-style heatmap: 7 weekday rows × N week columns, each cell colored
/// by the day's completion ratio. One [CustomPainter] paints the whole grid
/// instead of ~380 individual widgets (layout cost on low-end devices).
class GithubHeatmap extends StatelessWidget {
  const GithubHeatmap({
    required this.days,
    this.cellSize = 12,
    this.gap = 3,
    super.key,
  });

  /// Last 365 days, oldest first.
  final List<DayCompletion> days;
  final double cellSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final first = days.first.date;
    final last = days.last.date;

    // Align the first week to Monday so columns line up.
    final mondayOffset = first.weekday - 1;
    final gridStart = first.subtract(Duration(days: mondayOffset));

    final totalDays = last.difference(gridStart).inDays + 1;
    final weekCount = (totalDays / 7).ceil();

    const labelWidth = 18.0;
    const monthLabelHeight = 14.0;
    const labelGap = 2.0;

    final gridWidth = weekCount * (cellSize + gap);
    final totalWidth = labelWidth + gridWidth;
    final totalHeight = monthLabelHeight + labelGap + 7 * (cellSize + gap);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: CustomPaint(
        size: Size(totalWidth, totalHeight),
        painter: _HeatmapPainter(
          days: days,
          gridStart: gridStart,
          first: first,
          last: last,
          weekCount: weekCount,
          cellSize: cellSize,
          gap: gap,
          labelWidth: labelWidth,
          monthLabelHeight: monthLabelHeight,
          labelGap: labelGap,
          weekdayLabelStyle: theme.textTheme.labelSmall?.copyWith(fontSize: 8),
          monthLabelStyle: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
          onSurface: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.days,
    required this.gridStart,
    required this.first,
    required this.last,
    required this.weekCount,
    required this.cellSize,
    required this.gap,
    required this.labelWidth,
    required this.monthLabelHeight,
    required this.labelGap,
    required this.weekdayLabelStyle,
    required this.monthLabelStyle,
    required this.onSurface,
  });

  final List<DayCompletion> days;
  final DateTime gridStart;
  final DateTime first;
  final DateTime last;
  final int weekCount;
  final double cellSize;
  final double gap;
  final double labelWidth;
  final double monthLabelHeight;
  final double labelGap;
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
    for (var week = 0; week < weekCount; week++) {
      String? label;
      for (var dow = 0; dow < 7; dow++) {
        final date = gridStart.add(Duration(days: week * 7 + dow));
        if (date.day == 1 && !date.isBefore(first) && !date.isAfter(last)) {
          label = monthNames[date.month].substring(0, 3);
          break;
        }
      }
      if (label == null) continue;
      textPainter.text = TextSpan(text: label, style: monthLabelStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelWidth + week * (cellSize + gap), 0),
      );
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
      textPainter.paint(
        canvas,
        Offset(0, monthLabelHeight + labelGap + dow * (cellSize + gap)),
      );
    }

    // ── Cells ─────────────────────────────────────────────────
    final paint = Paint();
    for (var week = 0; week < weekCount; week++) {
      for (var dow = 0; dow < 7; dow++) {
        final date = gridStart.add(Duration(days: week * 7 + dow));
        final comp = _dayByDate[date];
        final inRange = !date.isBefore(first) && !date.isAfter(last);
        final color = inRange && comp != null
            ? _cellColor(comp.ratio)
            : Colors.transparent;
        if (color == Colors.transparent) continue;
        paint.color = color;
        final left = labelWidth + week * (cellSize + gap);
        final top = monthLabelHeight + labelGap + dow * (cellSize + gap);
        final rect = Rect.fromLTWH(left, top, cellSize, cellSize);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
          paint,
        );
      }
    }
  }

  Color _cellColor(double ratio) {
    if (ratio <= 0.0) {
      return onSurface.withValues(alpha: 0.08);
    }
    if (ratio < 0.25) return AppColors.sageGreen.withValues(alpha: 0.35);
    if (ratio < 0.5) return AppColors.sageGreen.withValues(alpha: 0.6);
    if (ratio < 0.75) return AppColors.sageGreen.withValues(alpha: 0.85);
    return AppColors.emeraldGlow;
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) {
    return !identical(oldDelegate.days, days) ||
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
        for (final alpha in const [0.08, 0.35, 0.6, 0.85, 1.0]) ...[
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: alpha == 1.0
                  ? AppColors.emeraldGlow
                  : alpha == 0.08
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                  : AppColors.sageGreen.withValues(alpha: alpha),
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
