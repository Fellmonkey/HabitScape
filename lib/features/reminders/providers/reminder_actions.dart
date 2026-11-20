import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_settings.dart';
import '../../../core/settings/hintful.dart';
import '../../../core/settings/today.dart';
import '../../onboarding/presentation/app_tours.dart';
import '../domain/reminder_spec.dart';
import 'reminder_scheduler_provider.dart';

/// Result of a settings-toggle attempt. Denial needs a hint; success only
/// flips the switch.
enum ReminderToggleResult { enabled, disabled, permissionDenied }

/// Orchestrates reminder onboarding and the settings toggle. Widgets call one
/// command and render the outcome; permission, persistence and sequencing stay
/// out of build methods.
class ReminderActions extends Notifier<void> {
  @override
  void build() {}

  /// Whether the one-time explainer is still due.
  Future<bool> isFirstLaunchPromptDue() async {
    final answered = await ref
        .read(notificationActionsProvider.notifier)
        .promptAlreadyAnswered();
    return !answered;
  }

  /// Waits for the first-run greenhouse tour to settle so the explainer never
  /// stacks on top of it. Bounded by a deadline and an iteration cap so a
  /// pinned test clock cannot turn this into an endless poll.
  Future<void> waitForOnboarding() async {
    final store = await ref.read(hintfulStoreProvider.future);
    final clock = ref.read(clockProvider);
    final deadline = clock.now().add(const Duration(seconds: 12));
    for (var i = 0; i < 48 && clock.now().isBefore(deadline); i++) {
      if (!store.shouldShow(AppTourIds.greenhouse)) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  /// Applies the explainer answer: resolves the scope, asks the OS only for a
  /// positive choice, and persists the decision via NotificationActions.
  Future<void> applyFirstLaunchChoice(ReminderScope scope) async {
    final Set<ReminderKind>? kinds = switch (scope) {
      ReminderScope.all => ReminderKind.values.toSet(),
      ReminderScope.essentials => const {
        ReminderKind.weekSummary,
        ReminderKind.monthSummary,
        ReminderKind.moment,
      },
      ReminderScope.none => null,
    };
    final allowed = kinds == null
        ? false
        : await ref.read(reminderSchedulerProvider).requestPermission();
    await ref
        .read(notificationActionsProvider.notifier)
        .finishFirstLaunchPrompt(kinds: kinds, allowed: allowed);
  }

  /// Toggles reminders from settings. Enabling asks the OS first; a denial
  /// leaves the stored setting untouched.
  Future<ReminderToggleResult> toggle(bool value) async {
    if (value) {
      final granted = await ref
          .read(reminderSchedulerProvider)
          .requestPermission();
      if (!granted) return ReminderToggleResult.permissionDenied;
    }
    await ref.read(notificationActionsProvider.notifier).setEnabled(value);
    return value ? ReminderToggleResult.enabled : ReminderToggleResult.disabled;
  }
}

final reminderActionsProvider = NotifierProvider<ReminderActions, void>(
  ReminderActions.new,
);
