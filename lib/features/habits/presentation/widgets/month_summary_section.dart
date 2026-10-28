import 'package:flutter/material.dart' hide TimeOfDay;

import '../../../../core/database/enums.dart';
import '../../../../core/domain/completion.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';

/// Mood chips, completion over the month's elapsed days, and the
/// written-moments counter. Pure presentation: everything numeric arrives
/// precomputed in [MonthSpreadSummary].
class MonthSummarySection extends StatelessWidget {
  const MonthSummarySection({required this.summary, super.key});

  final MonthSpreadSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodCounts = summary.moodCounts;
    final progress = summary.completionPct;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MonthMoodCount(
              mood: DayMood.good,
              count: moodCounts[DayMood.good]!,
            ),
            const SizedBox(width: 12),
            MonthMoodCount(mood: DayMood.ok, count: moodCounts[DayMood.ok]!),
            const SizedBox(width: 12),
            MonthMoodCount(mood: DayMood.bad, count: moodCounts[DayMood.bad]!),
            const Spacer(),
            Text(
              '${summary.momentsCount} ${pluralMoments(summary.momentsCount)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Выполнено за месяц', style: theme.textTheme.labelSmall),
              const Spacer(),
              Text(
                '${progress.round()}%',
                key: K.monthSpreadProgress,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: progressColor(
                    progress,
                    good: context.palette.sage,
                    okay: context.palette.amber,
                    bad: context.palette.rose,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.borderS,
            child: LinearProgressIndicator(
              value: progress / 100.0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(
                progressColor(
                  progress,
                  good: context.palette.sage,
                  okay: context.palette.amber,
                  bad: context.palette.rose,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One colored mood count chip in the summary row.
class MonthMoodCount extends StatelessWidget {
  const MonthMoodCount({required this.mood, required this.count, super.key});

  final DayMood mood;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: mood.color(context).withValues(alpha: 0.14),
        borderRadius: AppRadius.borderM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: mood.color(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
