import 'package:flutter/material.dart';

import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../../../core/utils/time_bucket.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/rhythm_stats.dart';

/// Weekly rhythm card: best/worst weekday and peak activity time.
class RhythmCard extends StatelessWidget {
  const RhythmCard({super.key, required this.rhythm});

  final RhythmStats rhythm;

  /// Russian label for the typed bucket — the only place the bucket becomes
  /// human text.
  static String _timeLabel(TimeBucket bucket) => switch (bucket) {
    TimeBucket.morning => 'утром',
    TimeBucket.day => 'днём',
    TimeBucket.evening => 'вечером',
    TimeBucket.night => 'ночью',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = rhythm.bestWeekday;
    final worst = rhythm.worstWeekday;
    final timeBucket = rhythm.timeBucket;

    if (best == null && timeBucket == null) {
      return Container(
        key: K.statsRhythm,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppCardHeader(
              icon: Icons.schedule_rounded,
              title: 'Ритм недели',
            ),
            const SizedBox(height: 12),
            Text(
              'Пока мало данных — веди привычки несколько дней.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: K.statsRhythm,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCardHeader(
            icon: Icons.schedule_rounded,
            title: 'Ритм недели',
          ),
          const SizedBox(height: 10),
          if (best != null)
            _RhythmRow(
              icon: Icons.thumb_up_alt_rounded,
              color: AppColors.sageGreen,
              text: 'Лучший день: ${weekdayNames[best]} — ${_pctOf(best)}%',
            ),
          if (worst != null)
            _RhythmRow(
              icon: Icons.thumb_down_alt_rounded,
              color: AppColors.dustyRose,
              text: 'Худший день: ${weekdayNames[worst]} — ${_pctOf(worst)}%',
            ),
          if (timeBucket != null)
            _RhythmRow(
              icon: Icons.schedule_rounded,
              color: AppColors.warmAmber,
              text:
                  'Пик активности: ${_timeLabel(timeBucket)} — ${rhythm.timeShare.round()}%',
            ),
        ],
      ),
    );
  }

  int _pctOf(int weekday) => (rhythm.weekdays[weekday - 1].ratio * 100).round();
}

class _RhythmRow extends StatelessWidget {
  const _RhythmRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
