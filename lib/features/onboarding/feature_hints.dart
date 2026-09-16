import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings/shared_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helpers.dart';

const _firstUseKey = 'first_use_date';
const _dismissedHintsKey = 'dismissed_feature_hints';

class FeatureHint {
  const FeatureHint({required this.key, required this.message, required this.minDays});
  final String key;
  final String message;
  final int minDays;
}

const featureHints = <FeatureHint>[
  FeatureHint(
    key: 'echo',
    message: 'Открылось Эхо: прошлые моменты теперь показываются под Моментом дня.',
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

int _ensureFirstUse(SharedPreferences prefs) {
  final existing = prefs.getInt(_firstUseKey);
  if (existing != null) return existing;
  final now = DateTime.now().toMidnight.unixSeconds;
  prefs.setInt(_firstUseKey, now);
  return now;
}

FeatureHint? activeFeatureHint(SharedPreferences prefs) {
  final firstUse = _ensureFirstUse(prefs);
  final today = DateTime.now().toMidnight.unixSeconds;
  final days = ((today - firstUse) / 86400).floor();
  final dismissed = prefs.getStringList(_dismissedHintsKey)?.toSet() ?? <String>{};
  FeatureHint? result;
  for (final hint in featureHints) {
    if (days >= hint.minDays && !dismissed.contains(hint.key)) {
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
    final prefsAsync = ref.watch(sharedPrefsProvider);
    return prefsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (prefs) {
        final hint = activeFeatureHint(prefs);
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
                    child: Text(
                      hint.message,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      final dismissed = prefs.getStringList(_dismissedHintsKey)?.toList() ?? <String>[];
                      if (!dismissed.contains(hint.key)) dismissed.add(hint.key);
                      prefs.setStringList(_dismissedHintsKey, dismissed);
                      setState(() {});
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
