import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reminders/domain/reminder_spec.dart';
import '../settings/shared_prefs.dart';

/// Whether local reminders are enabled. Opt-in: default off, so a fresh
/// install never nags without the user asking for it.
final notificationEnabledProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return prefs.getBool(notificationEnabledKey) ?? false;
});

const notificationEnabledKey = 'notifications_enabled';

/// The user-chosen scope of reminders. Absent = everything (legacy / before
/// the first-launch prompt).
final notificationKindsProvider = FutureProvider<Set<ReminderKind>>((
  ref,
) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  final raw = prefs.getStringList(notificationKindsKey) ?? const [];
  if (raw.isEmpty) return ReminderKind.values.toSet();
  return {
    for (final name in raw)
      if (ReminderKind.values.any((k) => k.name == name))
        ReminderKind.values.firstWhere((k) => k.name == name),
  };
});

const notificationKindsKey = 'notifications_kinds';

/// Whether the first-launch explainer was already shown/answered.
const notificationPromptedKey = 'notifications_prompted';

/// The single command surface for the reminders toggle and first-launch
/// prompt.
class NotificationActions extends Notifier<void> {
  @override
  void build() {}

  Future<void> setEnabled(bool value) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setBool(notificationEnabledKey, value);
    ref.invalidate(notificationEnabledProvider);
  }

  Future<void> setKinds(Set<ReminderKind> kinds) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setStringList(
      notificationKindsKey,
      kinds.map((k) => k.name).toList(),
    );
    ref.invalidate(notificationKindsProvider);
  }

  /// Records the first-launch answer. [allowed] is whether the OS granted
  /// permission for the chosen scope; when false reminders stay off.
  Future<void> finishFirstLaunchPrompt({
    required Set<ReminderKind>? kinds,
    required bool allowed,
  }) async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setBool(notificationPromptedKey, true);
    if (kinds == null) {
      await setEnabled(false);
      return;
    }
    if (!allowed) {
      await setEnabled(false);
      return;
    }
    await setKinds(kinds);
    await setEnabled(true);
  }
}

final notificationActionsProvider = NotifierProvider<NotificationActions, void>(
  NotificationActions.new,
);
