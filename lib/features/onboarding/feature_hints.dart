import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/exposure.dart';
import '../../core/settings/haptics.dart';
import '../../core/theme/app_theme.dart';

class FeatureHint {
  const FeatureHint({
    required this.key,
    required this.message,
    required this.minDays,
  });
  final String key;
  final String message;
  final int minDays;
}

const featureHints = <FeatureHint>[
  FeatureHint(
    key: 'echo',
    message:
        'Открылось Эхо: прошлые моменты теперь показываются под Моментом дня.',
    minDays: 3,
  ),
  FeatureHint(
    key: 'week_summary',
    message: 'Открылся Итог недели: по воскресеньям появляется мягкое резюме.',
    minDays: 7,
  ),
  FeatureHint(
    key: 'month_goals',
    message: 'Открылись Цели месяца: их можно вести в Развороте месяца.',
    minDays: 14,
  ),
  FeatureHint(
    key: 'capsules',
    message: 'Открылись Капсулы времени: письмо себе в будущее.',
    minDays: 30,
  ),
];

/// The newest hint that has matured and is still undismissed. Pure: the
/// exposure snapshot owns first-use and dismissal state.
FeatureHint? activeFeatureHint(Exposure exposure) {
  FeatureHint? result;
  for (final hint in featureHints) {
    if (exposure.hintVisible(key: hint.key, minDays: hint.minDays)) {
      result = hint; // last matching by minDays order
    }
  }
  return result;
}

class FeatureHintBanner extends ConsumerStatefulWidget {
  const FeatureHintBanner({super.key});

  @override
  ConsumerState<FeatureHintBanner> createState() => _FeatureHintBannerState();
}

class _FeatureHintBannerState extends ConsumerState<FeatureHintBanner> {
  @override
  Widget build(BuildContext context) {
    final exposureAsync = ref.watch(exposureProvider);
    return exposureAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (exposure) {
        final hint = activeFeatureHint(exposure);
        if (hint == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Material(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: AppRadius.borderM,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(hint.message, style: theme.textTheme.bodySmall),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    tooltip: 'Скрыть подсказку',
                    onPressed: () async {
                      Haptics.tap(ref.read(hapticsEnabledProvider));
                      await ref
                          .read(exposureActionsProvider.notifier)
                          .dismissHint(hint.key);
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
