import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Haptics on/off switch.
class HapticsTile extends ConsumerWidget {
  const HapticsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(hapticsEnabledProvider);
    final theme = Theme.of(context);
    return GlassCard(
      child: SwitchListTile(
        key: K.hapticsToggle,
        secondary: Icon(Icons.vibration, color: theme.colorScheme.primary),
        title: Text('Вибрация', style: theme.textTheme.titleSmall),
        subtitle: Text(
          'Тактильный отклик при отметках и нажатиях',
          style: theme.textTheme.bodySmall,
        ),
        value: enabled,
        onChanged: (value) =>
            ref.read(hapticsEnabledProvider.notifier).setEnabled(value),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
      ),
    );
  }
}
