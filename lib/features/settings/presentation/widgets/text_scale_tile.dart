import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/text_scale.dart';
import '../../../../core/theme/app_theme.dart';

/// In-app text scale picker: system-following or a fixed factor.
/// Compact chips instead of a segmented control so labels never overflow or
/// shift layout on narrow screens.
class TextScaleTile extends ConsumerWidget {
  const TextScaleTile({super.key});

  String _shortLabel(TextScaleOption option) => switch (option) {
    TextScaleOption.system => 'Системная',
    TextScaleOption.standard => '1.0',
    TextScaleOption.larger => '1.15',
    TextScaleOption.extraLarge => '1.3',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(textScaleProvider);
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Размер текста', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Дополнительно к системному масштабу',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              key: K.textScalePicker,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in TextScaleOption.values)
                  ChoiceChip(
                    label: Text(_shortLabel(option)),
                    selected: current == option,
                    onSelected: (_) =>
                        ref.read(textScaleProvider.notifier).set(option),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
