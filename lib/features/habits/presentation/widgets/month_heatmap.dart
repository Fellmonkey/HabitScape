import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/calendar_grid.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../providers/habit_metrics_providers.dart';

/// One month of a habit's check-offs as a calendar grid, coloured by status.
class MonthHeatmap extends ConsumerWidget {
  const MonthHeatmap({
    required this.habitId,
    required this.year,
    required this.month,
    super.key,
  });

  final int habitId, year, month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider fetches once per visit and is shared with metrics.
    final logsAsync = ref.watch(
      habitMonthLogsProvider((habitId: habitId, year: year, month: month)),
    );
    final today = ref.watch(todayDateProvider);

    return logsAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const SizedBox(height: 120),
      data: (logs) =>
          HeatmapGrid(logs: logs, year: year, month: month, today: today),
    );
  }
}

class HeatmapGrid extends StatelessWidget {
  const HeatmapGrid({
    required this.logs,
    required this.year,
    required this.month,
    required this.today,
    super.key,
  });

  final List<HabitLog> logs;
  final int year, month;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grid = CalendarGrid.month(
      month: DateTime.utc(year, month),
      today: today,
    );

    final statusMap = <int, LogStatus>{}; // day → status
    for (final log in logs) {
      final d = dateFromUnix(log.date);
      if (d.year == year && d.month == month) {
        statusMap[d.day] = log.status;
      }
    }

    // Weekday header
    return Column(
      children: [
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Center(
                child: Text(
                  shortWeekdayNames[i + 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        for (final week in grid.weeks)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                for (final cell in week)
                  if (cell == null)
                    const Expanded(child: SizedBox(height: 36))
                  else
                    Expanded(
                      child: DayCell(
                        day: cell.date.day,
                        status: statusMap[cell.date.day],
                        isToday: cell.isToday,
                        isFuture: cell.isFuture,
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class DayCell extends StatelessWidget {
  const DayCell({
    required this.day,
    required this.status,
    required this.isToday,
    required this.isFuture,
    super.key,
  });

  final int day;
  final LogStatus? status;
  final bool isToday, isFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? bgColor;
    Color textColor = theme.colorScheme.onSurface;

    if (isFuture) {
      textColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);
    } else if (status != null) {
      switch (status!) {
        case LogStatus.done:
          bgColor = context.palette.sage.withValues(alpha: 0.35);
        case LogStatus.skip:
          bgColor = context.palette.greyBlue.withValues(alpha: 0.25);
        case LogStatus.pending:
          bgColor = theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.15,
          );
      }
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.borderS,
        border: isToday
            ? Border.all(color: theme.colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: theme.textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ),
    );
  }
}
