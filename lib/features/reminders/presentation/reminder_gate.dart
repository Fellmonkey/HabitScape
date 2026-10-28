import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';
import '../../../core/domain/moment.dart';
import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/notifications/reminder_settings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/settings/exposure.dart';
import '../../../core/settings/shared_prefs.dart';
import '../../../core/settings/today.dart';
import '../../habits/providers/day_note_providers.dart';
import '../../habits/providers/habit_streams.dart';
import '../../habits/providers/month_summary_providers.dart';
import '../../week/providers/week_providers.dart';
import '../domain/reminder_spec.dart';
import '../domain/reminder_templates.dart';

/// Owns the live reminder schedule. It watches the app state (habits, today's
/// logs, week/month windows, today's note, the toggle, the chosen scope) and
/// on any change reconciles the OS schedule to the expected template set —
/// scheduling new reminders, cancelling obsolete ones (a done habit, an
/// answered summary, a written moment) and dropping everything when reminders
/// are disabled.
///
/// Also owns the first-launch explainer: once per install it asks whether to
/// allow notifications and which kinds, so the user understands what will
/// arrive and that it is not spam (local, offline). Renders nothing; it is a
/// side-effect host mounted above the router.
class ReminderGate extends ConsumerStatefulWidget {
  const ReminderGate({required this.child, super.key});

  /// The app tree this gate hosts.
  final Widget child;

  @override
  ConsumerState<ReminderGate> createState() => _ReminderGateState();
}

class _ReminderGateState extends ConsumerState<ReminderGate> {
  String? _sig;
  final Map<int, String> _scheduled = {};

  @override
  void initState() {
    super.initState();
    final scheduler = ref.read(reminderSchedulerProvider);
    scheduler.initialize();
    scheduler.setNotificationTapHandler(_handleTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAskFirstLaunch());
  }

  void _handleTap(String? payload) {
    final context = rootNavigatorKey.currentContext;
    if (context == null || payload == null || payload == '/') return;
    GoRouter.of(context).push(payload);
  }

  /// One-time first-launch explainer. Skips on web (no notifications) and
  /// when a decision is already recorded.
  Future<void> _maybeAskFirstLaunch() async {
    if (kIsWeb || !mounted) return;
    final prefs = await ref.read(sharedPrefsProvider.future);
    if (prefs.getBool(notificationPromptedKey) ?? false) return;
    if (prefs.getBool(notificationEnabledKey) ?? false) {
      // Enabled before the prompt existed — treat as answered.
      await prefs.setBool(notificationPromptedKey, true);
      return;
    }

    final context = rootNavigatorKey.currentContext;
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

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(notificationEnabledProvider).value ?? false;
    final kinds = ref.watch(notificationKindsProvider).value;
    final scheduler = ref.watch(reminderSchedulerProvider);
    final habits = ref.watch(activeHabitsProvider).value ?? const <Habit>[];
    final logs = ref.watch(todayLogsProvider).value ?? const <HabitLog>[];
    final week = ref.watch(weekSummaryProvider).value;
    final month = ref.watch(monthSummaryProvider).value;
    final note = ref.watch(todayDayNoteProvider).value;
    final exposure = ref.watch(exposureProvider).value;
    final today = ref.watch(todayDateProvider);

    final specs = enabled && kinds != null
        ? buildReminderSpecs(
            habits: habits,
            doneTodayHabitIds: {
              for (final log in logs)
                if (log.status == LogStatus.done) log.habitId,
            },
            weekSummaryAvailable: week?.shouldShow ?? false,
            monthSummaryAvailable: month?.shouldShow ?? false,
            hasNoteToday: note != null && hasMoment(note.moment),
            today: today,
            lastSeenDate: exposure?.lastSeenDate,
            enabledKinds: kinds,
          )
        : const <ReminderSpec>[];

    final sig = specs.map((s) => s.signature).join('\n');
    if (sig != _sig) {
      _sig = sig;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _apply(scheduler, specs, enabled),
      );
    }
    return widget.child;
  }

  Future<void> _apply(
    ReminderScheduler scheduler,
    List<ReminderSpec> specs,
    bool enabled,
  ) async {
    if (!enabled || !await scheduler.permissionGranted()) {
      await scheduler.cancelAll();
      _scheduled.clear();
      return;
    }

    final next = {for (final spec in specs) spec.id: spec.signature};
    final wanted = next.keys.toSet();

    for (final id in _scheduled.keys.toList()) {
      if (!wanted.contains(id)) {
        await scheduler.cancel(id);
        _scheduled.remove(id);
      }
    }

    for (final spec in specs) {
      if (_scheduled[spec.id] == spec.signature) continue;
      if (_scheduled.containsKey(spec.id)) {
        await scheduler.cancel(spec.id);
      }
      if (spec.repeatsDaily) {
        await scheduler.scheduleDaily(spec);
      } else {
        await scheduler.scheduleOneShot(spec);
      }
      _scheduled[spec.id] = spec.signature;
    }
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
