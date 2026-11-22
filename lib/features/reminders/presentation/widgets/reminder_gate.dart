import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' hide TimeOfDay;

import '../../../../core/router/app_router.dart';
import '../../domain/reminder_spec.dart';
import '../../providers/reminder_actions.dart';
import '../../providers/reminder_specs_provider.dart';
import '../../providers/reminder_sync_provider.dart';

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
    final actions = ref.read(reminderActionsProvider.notifier);
    if (!await actions.isFirstLaunchPromptDue()) return;

    // Let the greenhouse tour finish first so the two teaching surfaces never
    // stack on the very first frame. The wait itself is owned by the Notifier.
    if (widget.waitForOnboarding) await actions.waitForOnboarding();
    if (!mounted) return;

    final context = ref.read(rootNavigatorKeyProvider).currentContext;
    if (context == null || !context.mounted) return;

    final scope = await showDialog<ReminderScope>(
      context: context,
      builder: (context) => const _FirstLaunchPromptDialog(),
    );
    if (!mounted || scope == null) return;

    await actions.applyFirstLaunchChoice(scope);
  }

  @override
  Widget build(BuildContext context) {
    // Listening (instead of a post-frame callback in build) also performs the
    // initial reconcile on mount; the provider's signature suppresses no-ops.
    ref.listen(reminderSpecsProvider, (_, next) {
      unawaited(
        ref.read(reminderSyncProvider.notifier).sync(next.specs, next.enabled),
      );
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
          onPressed: () => Navigator.of(context).pop(ReminderScope.essentials),
          child: const Text('Только итоги и момент'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ReminderScope.all),
          child: const Text('Включить все'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ReminderScope.none),
          child: const Text('Не сейчас'),
        ),
      ],
    );
  }
}
