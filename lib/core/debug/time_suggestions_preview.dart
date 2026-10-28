import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/stats/presentation/widgets/time_suggestion_card.dart';
import '../../features/stats/providers/habit_lifecycle_providers.dart';
import '../keys.dart';

/// Debug preview of «Подсказка»: shows the stats time-suggestion card with
/// live data, or an explanation when there is nothing to suggest yet.
class TimeSuggestionsPreviewSheet extends ConsumerWidget {
  const TimeSuggestionsPreviewSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(timeSuggestionsProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        key: K.debugSuggestionsPreview,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Подсказки — превью',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Так выглядит карточка «Подсказка» в статистике. Совет '
              'появляется, когда фактический пик отметок расходится с '
              'настроенным временем суток.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            suggestionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text(e.toString(), style: theme.textTheme.bodyMedium),
              data: (suggestions) {
                if (suggestions.isEmpty) {
                  return Text(
                    'Советов нет. Запусти сценарий «Совет по времени: '
                    'данные созданы».',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  );
                }
                return const TimeSuggestionCard();
              },
            ),
          ],
        ),
      ),
    );
  }
}
