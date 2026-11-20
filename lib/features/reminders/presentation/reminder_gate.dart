import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/notifications/reminder_settings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/hintful.dart';
import '../../../core/settings/today.dart';
import '../../onboarding/app_tours.dart';
import '../domain/reminder_spec.dart';
import '../providers/reminder_specs_provider.dart';
import '../providers/reminder_sync_provider.dart';

/// Side-effect host for the live reminder schedule. The expected spec set is
/// derived by `reminderSpecsProvider`; this widget only reconciles it with the
/// OS scheduler (scheduling new reminders, cancelling obsolete ones, dropping
/// everything when reminders are disabled).
///
/// Also owns the first-launch explainer: once per install it asks whether to
/// allow notifications and which kinds, so the user understands what will
/// arrive and that it is not spam (local, offline). Renders nothing; it is a
/// side-effect host mounted above the router.
class ReminderGate extends ConsumerStatefulWidget {
  const ReminderGate({
    required this.child,
    this.waitForOnboarding = true,
    super.key,
  });

  /// The app tree this gate hosts.
  final Widget child;

  /// Whether the first-launch explainer waits for the first-run greenhouse
  /// tour to settle before showing itself — so two teaching surfaces never
  /// stack on the very first frame. Tests without a screen pass false.
  final bool waitForOnboarding;

  @override
  ConsumerState<ReminderGate> createState() => _ReminderGateState();
}

class _ReminderGateState extends ConsumerState<ReminderGate> {
  @override
  void initState() {
    super.initState();
    ref.read(reminderSyncProvider.notifier).initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskFirstLaunch());
  }

  /// One-time first-launch explainer. Skips on web (no notifications) and
  /// when a decision is already recorded.
  Future<void> _maybeAskFirstLaunch() async {
    if (kIsWeb || !mounted) return;
    if (await ref
        .read(notificationActionsProvider.notifier)
        .promptAlreadyAnswered()) {
      return;
    }

    // Serialize the very first-frame teaching: let the greenhouse tour show
    // (and finish/skip) first, so the dialog never stacks on top of it.
    if (widget.waitForOnboarding) {
      await _waitForGreenhouseTour();
    }

    final context = ref.read(rootNavigatorKeyProvider).currentContext;
    if (context == null || !context.mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => const _FirstLaunchPromptDialog(),
    );
    if (!mounted || choice == null) return;

    final allowed = choice == 'all' || choice == 'essentials'
        ? await ref.read(reminderSchedulerProvider).requestPermission()
        : false;

    await ref
        .read(notificationActionsProvider.notifier)
        .finishFirstLaunchPrompt(
          kinds: switch (choice) {
            'all' => ReminderKind.values.toSet(),
            'essentials' => {
              ReminderKind.weekSummary,
              ReminderKind.monthSummary,
              ReminderKind.moment,
            },
            _ => null,
          },
          allowed: allowed,
        );
  }

  /// Waits up to a few seconds for the first-run greenhouse tour to finish
  /// (the tour marks itself on any exit — finish / skip / abort), so the
  /// reminders explainer never stacks on top of it. If the tour never
  /// starts (e.g. there is no screen to host it), the timeout bounds the
  /// wait so the prompt is never lost.
  Future<void> _waitForGreenhouseTour() async {
    final store = await ref.read(hintfulStoreProvider.future);
    final clock = ref.read(clockProvider);
    final deadline = clock.now().add(const Duration(seconds: 12));
    // The iteration cap keeps a pinned test clock from turning this into an
    // endless poll; production exits as soon as the tour marks itself done.
    for (var i = 0; i < 48 && clock.now().isBefore(deadline); i++) {
      if (!store.shouldShow(AppTourIds.greenhouse)) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  @override
  Widget build(BuildContext context) {
    final expected = ref.watch(reminderSpecsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(reminderSyncProvider.notifier)
          .sync(expected.specs, expected.enabled);
    });
    return widget.child;
  }
}

/// The one-time first-launch ask: what reminders are, what kinds exist, and
/// how much the user wants. The OS permission dialog (Android 13+) follows
/// only after a positive choice, so a "no" never triggers it.
class _FirstLaunchPromptDialog extends StatelessWidget {
  const _FirstLaunchPromptDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Напоминания'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Приложение может мягко напоминать о важном. Это локальные '
            'уведомления — они не уходят в интернет и не бывают спамом.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text('Что можно включить:', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          const Text('• привычки в их время дня и вечерний толчок'),
          const Text('• итоги недели и месяца'),
          const Text('• приглашение записать момент дня'),
          const Text('• мягкое напоминание, если ты не заходил несколько дней'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('essentials'),
          child: const Text('Только итоги и момент'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('all'),
          child: const Text('Включить все'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('none'),
          child: const Text('Не сейчас'),
        ),
      ],
    );
  }
}
