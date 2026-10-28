import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_bucket.dart';
import '../../../../shared/widgets/app_card_header.dart';
import '../../domain/time_suggestion.dart';
import '../../providers/habit_lifecycle_providers.dart';

/// «Подсказка»: time-of-day hints — a habit is routinely marked at a time
/// that disagrees with how it was configured. Shown only when there is enough
/// history to say so.
class TimeSuggestionCard extends ConsumerWidget {
  const TimeSuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(timeSuggestionsProvider);
    final theme = Theme.of(context);

    return Container(
      key: K.statsSuggestion,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: suggestionsAsync.when(
        loading: () => const SizedBox(height: 80),
        error: (_, _) => const SizedBox(height: 80),
        data: (suggestions) {
          if (suggestions.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppCardHeader(
                icon: Icons.lightbulb_outline_rounded,
                title: 'Подсказка',
              ),
              const SizedBox(height: 10),
              for (final suggestion in suggestions.take(3))
                _SuggestionRow(suggestion: suggestion),
            ],
          );
        },
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.suggestion});

  final TimeSuggestion suggestion;

  static String _bucketLabel(TimeBucket bucket) => switch (bucket) {
    TimeBucket.morning => 'утром',
    TimeBucket.day => 'днём',
    TimeBucket.evening => 'вечером',
    TimeBucket.night => 'ночью',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${suggestion.habit.name}: чаще отмечаешь '
              '${_bucketLabel(suggestion.actualBucket)} — попробуй '
              'перенести время (n=${suggestion.sampleSize})',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
