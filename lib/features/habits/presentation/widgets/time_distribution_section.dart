import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/habit_engine.dart';

/// When today's done-logs were recorded, as four labelled bars (morning,
/// day, evening, night).
class TimeDistributionSection extends StatelessWidget {
  const TimeDistributionSection({required this.metrics, super.key});

  final HabitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Время отметок', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            TimeBar(
              label: 'Утро',
              ratio: metrics.morningRatio,
              color: AppColors.sageGreen,
            ),
            const SizedBox(width: 8),
            TimeBar(
              label: 'День',
              ratio: metrics.afternoonRatio,
              color: AppColors.warmAmber,
            ),
            const SizedBox(width: 8),
            TimeBar(
              label: 'Вечер',
              ratio: metrics.eveningRatio,
              color: AppColors.softLavender,
            ),
            const SizedBox(width: 8),
            TimeBar(
              label: 'Ночь',
              ratio: metrics.nightRatio,
              color: AppColors.fadedPlum,
            ),
          ],
        ),
      ],
    );
  }
}

class TimeBar extends StatelessWidget {
  const TimeBar({
    required this.label,
    required this.ratio,
    required this.color,
    super.key,
  });

  final String label;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio.clamp(0.05, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    borderRadius: AppRadius.borderS,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text('${(ratio * 100).round()}%', style: theme.textTheme.bodySmall),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
