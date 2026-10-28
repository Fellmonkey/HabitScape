import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/text_scale.dart';
import '../../../../shared/widgets/glass_card.dart';

/// In-app text scale picker: system-following or a fixed factor.
class TextScaleTile extends ConsumerWidget {
  const TextScaleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(textScaleProvider);
    final theme = Theme.of(context);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Text('Размер текста', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Дополнительно к системному масштабу',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TextScaleOption>(
                key: K.textScalePicker,
                segments: [
                  for (final option in TextScaleOption.values)
                    ButtonSegment(value: option, label: Text(option.label)),
                ],
                selected: {current},
                onSelectionChanged: (selection) =>
                    ref.read(textScaleProvider.notifier).set(selection.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
