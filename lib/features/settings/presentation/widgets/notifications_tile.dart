import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/keys.dart';
import '../../../../core/notifications/reminder_scheduler.dart';
import '../../../../core/notifications/reminder_settings.dart';

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
    return SwitchListTile(
      key: K.settingsNotifications,
      secondary: const Icon(Icons.notifications_active_outlined),
      title: const Text('Напоминания'),
      subtitle: Text(
        enabled
            ? 'Уведомления о привычках и итогах включены'
            : 'Локальные уведомления — офлайн, на устройстве',
      ),
      value: enabled,
      onChanged: _busy ? null : _toggle,
    );
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      if (value) {
        final scheduler = ref.read(reminderSchedulerProvider);
        final granted = await scheduler.requestPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Разрешение на уведомления не выдано — '
                  'включите его в настройках системы',
                ),
              ),
            );
          }
          return;
        }
      }
      await ref.read(notificationActionsProvider.notifier).setEnabled(value);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
