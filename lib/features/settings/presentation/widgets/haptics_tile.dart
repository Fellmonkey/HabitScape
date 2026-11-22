import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_theme.dart';

/// Haptics on/off switch.
class HapticsTile extends ConsumerWidget {
  const HapticsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(hapticsEnabledProvider);
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        dense: true,
        key: K.hapticsToggle,
        secondary: Icon(Icons.vibration, color: theme.colorScheme.primary),
        title: Text('Вибрация', style: theme.textTheme.titleMedium),
        subtitle: Text(
          'Тактильный отклик при отметках и нажатиях',
          style: theme.textTheme.bodyMedium,
        ),
        value: enabled,
        onChanged: (value) =>
            ref.read(hapticsEnabledProvider.notifier).setEnabled(value),
      ),
    );
  }
}
