import 'package:flutter/material.dart';

import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/domain/completion.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/stats_engine.dart';
import 'github_heatmap.dart';

/// Year heatmap card: the full-year activity grid inside a card.
class HeatmapCard extends StatelessWidget {
  const HeatmapCard({
    super.key,
    required this.stats,
    required this.today,
    this.onDayTap,
  });

  final StatsOverview stats;

  /// The day that gets the "today" marker on the grid.
  final DateTime today;
  final ValueChanged<DayCompletion>? onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCardHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Активность за год',
          ),
          const SizedBox(height: 12),
          GithubHeatmap(
            key: K.statsHeatmap,
            days: stats.days,
            today: today,
            onDayTap: onDayTap,
          ),
          const SizedBox(height: 4),
          const HeatmapLegend(),
        ],
      ),
    );
  }
}
