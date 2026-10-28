import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/exposure.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_theme.dart';

/// The gesture-hint key — one-time, dismissible, independent of the feature
/// hints so it never competes with them for the single-banner slot.
const swipeHintKey = 'swipe_hint';

/// One-time teaching strip above the habit list: swipe right = done,
/// swipe left = skip. Hidden after the user dismisses it (or on a fresh
/// install before any habit exists — the caller only renders it then).
class SwipeHintStrip extends ConsumerWidget {
  const SwipeHintStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exposureAsync = ref.watch(exposureProvider);
    return exposureAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (exposure) {
        if (!exposure.hintVisible(key: swipeHintKey, minDays: 0)) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Material(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.28),
            borderRadius: AppRadius.borderM,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.swipe_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Свайпни вправо — выполнить, влево — пропустить.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Скрыть подсказку',
                    onPressed: () async {
                      Haptics.tap(ref.read(hapticsEnabledProvider));
                      await ref
                          .read(exposureActionsProvider.notifier)
                          .dismissHint(swipeHintKey);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
