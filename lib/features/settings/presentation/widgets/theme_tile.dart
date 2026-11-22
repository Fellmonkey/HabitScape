import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/theme_mode.dart';
import '../../../../core/theme/app_theme.dart';

/// Theme mode picker (system / light / dark).
class ThemeTile extends ConsumerWidget {
  const ThemeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mode = ref.watch(themeModeProvider);
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
                Icon(
                  Icons.palette_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text('Тема оформления', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                key: K.themeModePicker,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Системная'),
                  ),
                  ButtonSegment(value: ThemeMode.light, label: Text('Светлая')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Тёмная')),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  Haptics.tap(ref.read(hapticsEnabledProvider));
                  ref.read(themeModeProvider.notifier).setMode(selection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
