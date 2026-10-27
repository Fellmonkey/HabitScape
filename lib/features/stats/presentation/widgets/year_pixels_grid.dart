import 'package:flutter/material.dart' hide TimeOfDay;

import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';

/// «Год в пикселях»: twelve month rows of the trailing year, one cell per day,
/// colored by that day's mood. One [CustomPainter] paints the whole grid
/// (like the stats heatmap) so 372 cells are not 372 widgets.
class YearPixelsGrid extends StatelessWidget {
  const YearPixelsGrid({
    super.key,
    required this.moodByDay,
    required this.first,
    required this.today,
  });

  /// date → mood for every recorded day of the window.
  final Map<DateTime, DayMood> moodByDay;

  /// Window start (midnight, inclusive) — the oldest day of the trailing year.
  final DateTime first;

  final DateTime today;

  static const _gutter = 38.0;
  static const _gap = 2.0;
  static const _cols = 31;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayDay = today.toMidnight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final avail = constraints.maxWidth - _gutter;
        final cell = ((avail - _gap * (_cols - 1)) / _cols).clamp(4.0, 14.0);
        final height = 12 * (cell + _gap) + 8;

        return SizedBox(
          height: height,
          width: constraints.maxWidth,
          child: CustomPaint(
            key: K.yearPixelsGrid,
            painter: _PixelsPainter(
              moodByDay: moodByDay,
              first: first.toMidnight,
              today: todayDay,
              cellSize: cell,
              gap: _gap,
              gutter: _gutter,
              goodColor: context.palette.sage,
              okColor: context.palette.amber,
              badColor: context.palette.rose,
              emptyColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              futureColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              todayColor: theme.colorScheme.primary,
              monthLabelStyle: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PixelsPainter extends CustomPainter {
  _PixelsPainter({
    required this.moodByDay,
    required this.first,
    required this.today,
    required this.cellSize,
    required this.gap,
    required this.gutter,
    required this.goodColor,
    required this.okColor,
    required this.badColor,
    required this.emptyColor,
    required this.futureColor,
    required this.todayColor,
    required this.monthLabelStyle,
  });

  final Map<DateTime, DayMood> moodByDay;
  final DateTime first;
  final DateTime today;
  final double cellSize;
  final double gap;
  final double gutter;
  final Color goodColor;
  final Color okColor;
  final Color badColor;
  final Color emptyColor;
  final Color futureColor;
  final Color todayColor;
  final TextStyle? monthLabelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    // Twelve trailing months, oldest first.
    const months = 12;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    final paint = Paint();

    for (var m = 0; m < months; m++) {
      final monthStart = shiftMonths(first, m);
      final y = 6.0 + m * (cellSize + gap);

      // Month label in the gutter.
      final label = monthNames[monthStart.month].substring(0, 3);
      labelPainter.text = TextSpan(text: label, style: monthLabelStyle);
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          gutter - labelPainter.width - 6,
          y + (cellSize - labelPainter.height) / 2,
        ),
      );

      final days = daysInMonth(monthStart.year, monthStart.month);
      for (var day = 1; day <= days; day++) {
        final date = DateTime.utc(monthStart.year, monthStart.month, day);
        final x = gutter + (day - 1) * (cellSize + gap);
        final rect = Rect.fromLTWH(x, y, cellSize, cellSize);

        final mood = moodByDay[date];
        if (mood == null) {
          paint.color = date.isAfter(today) ? futureColor : emptyColor;
        } else {
          paint.color = switch (mood) {
            DayMood.good => goodColor,
            DayMood.ok => okColor,
            DayMood.bad => badColor,
          };
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2.5)),
          paint,
        );

        if (date == today) {
          final marker = Rect.fromLTWH(
            x - 1.5,
            y - 1.5,
            cellSize + 3,
            cellSize + 3,
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
  bool shouldRepaint(_PixelsPainter oldDelegate) {
    return !identical(oldDelegate.moodByDay, moodByDay) ||
        oldDelegate.first != first ||
        oldDelegate.today != today ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.goodColor != goodColor ||
        oldDelegate.okColor != okColor ||
        oldDelegate.badColor != badColor ||
        oldDelegate.emptyColor != emptyColor ||
        oldDelegate.futureColor != futureColor ||
        oldDelegate.todayColor != todayColor ||
        oldDelegate.monthLabelStyle != monthLabelStyle;
  }
}

/// Small legend for the mood pixels: good / okay / bad.
class MoodPixelsLegend extends StatelessWidget {
  const MoodPixelsLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget dot(Color color) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Row(
      children: [
        dot(context.palette.sage),
        const SizedBox(width: 5),
        Text('хорошо', style: theme.textTheme.labelSmall),
        const SizedBox(width: 14),
        dot(context.palette.amber),
        const SizedBox(width: 5),
        Text('так себе', style: theme.textTheme.labelSmall),
        const SizedBox(width: 14),
        dot(context.palette.rose),
        const SizedBox(width: 5),
        Text('плохо', style: theme.textTheme.labelSmall),
      ],
    );
  }
}
