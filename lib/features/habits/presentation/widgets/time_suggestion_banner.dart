import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/keys.dart';
import '../../../../core/providers/time_suggestions_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_bucket.dart';

/// «Подсказка» on the Greenhouse: a compact banner showing the first
/// time-of-day suggestion (a habit whose actual peak marking time disagrees
/// with its configured time). Hidden entirely when there is nothing to
/// suggest — it never renders as an empty card.
class TimeSuggestionBanner extends ConsumerWidget {
  const TimeSuggestionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(timeSuggestionsProvider);
    final theme = Theme.of(context);

    return suggestionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        final suggestion = suggestions.first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Material(
            key: K.greenhouseSuggestionBanner,
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.borderL,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${suggestion.habit.name}: чаще отмечаешь '
                      '${_timeLabel(suggestion.actualBucket)} — попробуй '
                      'перенести время (n=${suggestion.sampleSize})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _timeLabel(TimeBucket bucket) => switch (bucket) {
    TimeBucket.morning => 'утром',
    TimeBucket.day => 'днём',
    TimeBucket.evening => 'вечером',
    TimeBucket.night => 'ночью',
  };
}
