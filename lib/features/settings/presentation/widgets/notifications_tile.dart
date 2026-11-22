import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/keys.dart';
import '../../../../core/notifications/reminder_settings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../reminders/providers/reminder_actions.dart';

/// Opt-in toggle for local reminders. Enabling asks the OS for permission
/// first (Android 13+); a denial keeps reminders off with a hint.
class NotificationsTile extends ConsumerStatefulWidget {
  const NotificationsTile({super.key});

  @override
  ConsumerState<NotificationsTile> createState() => _NotificationsTileState();
}

class _NotificationsTileState extends ConsumerState<NotificationsTile> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(notificationEnabledProvider).value ?? false;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        dense: true,
        key: K.settingsNotifications,
        secondary: const Icon(Icons.notifications_active_outlined),
        title: Text('Напоминания', style: theme.textTheme.titleMedium),
        subtitle: Text(
          enabled
              ? 'Уведомления о привычках и итогах включены'
              : 'Локальные уведомления — офлайн, на устройстве',
          style: theme.textTheme.bodyMedium,
        ),
        value: enabled,
        onChanged: _busy ? null : _toggle,
      ),
    );
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(reminderActionsProvider.notifier)
          .toggle(value);
      if (result == ReminderToggleResult.permissionDenied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Разрешение на уведомления не выдано — '
              'включите его в настройках системы',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
