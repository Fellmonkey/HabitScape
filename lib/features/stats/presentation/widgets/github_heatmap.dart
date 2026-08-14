import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../domain/stats_engine.dart';

/// GitHub-style contribution heatmap: 7 rows (weekdays) × N columns (weeks).
/// Each cell is colored by the day's completion ratio.
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

    final dayByDate = <DateTime, DayCompletion>{
      for (final d in days) d.date: d,
    };

    final totalDays = last.difference(gridStart).inDays + 1;
    final weekCount = (totalDays / 7).ceil();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day-of-week labels (only Mon/Wed/Fri)
          SizedBox(
            width: 18,
            child: Column(
              children: List.generate(7, (dow) {
                final label = switch (dow) {
                  0 => 'Пн',
                  2 => 'Ср',
                  4 => 'Пт',
                  _ => '',
                };
                return SizedBox(
                  height: cellSize + gap,
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 8),
                  ),
                );
              }),
            ),
          ),
          // Month labels + grid
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month labels: show the month name in the first week that
              // contains the 1st of a month.
              SizedBox(
                height: 14,
                child: Row(
                  children: List.generate(weekCount, (week) {
                    String label = '';
                    for (var dow = 0; dow < 7; dow++) {
                      final date = gridStart.add(
                        Duration(days: week * 7 + dow),
                      );
                      if (date.day == 1 &&
                          !date.isBefore(first) &&
                          !date.isAfter(last)) {
                        label = monthNames[date.month].substring(0, 3);
                        break;
                      }
                    }
                    return SizedBox(
                      width: cellSize + gap,
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.clip,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 2),
              // Grid columns
              Row(
                children: List.generate(weekCount, (week) {
                  return Column(
                    children: List.generate(7, (dow) {
                      final date = gridStart.add(
                        Duration(days: week * 7 + dow),
                      );
                      final comp = dayByDate[date];
                      final inRange =
                          !date.isBefore(first) && !date.isAfter(last);
                      final color = inRange && comp != null
                          ? _cellColor(comp.ratio, theme)
                          : Colors.transparent;
                      return Container(
                        width: cellSize,
                        height: cellSize,
                        margin: EdgeInsets.only(right: gap, bottom: gap),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _cellColor(double ratio, ThemeData theme) {
    if (ratio <= 0.0) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.08);
    }
    if (ratio < 0.25) return AppColors.sageGreen.withValues(alpha: 0.35);
    if (ratio < 0.5) return AppColors.sageGreen.withValues(alpha: 0.6);
    if (ratio < 0.75) return AppColors.sageGreen.withValues(alpha: 0.85);
    return AppColors.emeraldGlow;
  }
}

/// Small legend for the heatmap («Меньше → Больше»).
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
