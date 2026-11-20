import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../domain/reconcile_reminders.dart';
import '../domain/reminder_spec.dart';
import 'reminder_scheduler_provider.dart';

/// Immutable snapshot of the live OS schedule. Exposed through Riverpod so
/// state is observable and testable instead of hidden in private fields.
class ReminderSyncState {
  const ReminderSyncState({this.signature, this.scheduled = const {}});

  final String? signature;
  final Map<int, String> scheduled;

  ReminderSyncState copyWith({String? signature, Map<int, String>? scheduled}) {
    return ReminderSyncState(
      signature: signature ?? this.signature,
      scheduled: scheduled ?? this.scheduled,
    );
  }
}

/// Owns the live OS schedule: a single signature guards no-op reconciles and
/// the scheduled-id map lets cancellations target only obsolete reminders.
/// The widget only computes the expected spec set and calls [sync].
final reminderSyncProvider = NotifierProvider<ReminderSync, ReminderSyncState>(
  ReminderSync.new,
);

class ReminderSync extends Notifier<ReminderSyncState> {
  @override
  ReminderSyncState build() => const ReminderSyncState();

  void initialize() {
    final scheduler = ref.read(reminderSchedulerProvider);
    scheduler.initialize();
    scheduler.setNotificationTapHandler(handleTap);
  }

  void handleTap(String? payload) {
    if (payload == null || payload == '/') return;
    ref.read(appRouterProvider).push(payload);
  }

  /// Reconciles the OS schedule to [specs] when the inputs actually changed.
  void sync(List<ReminderSpec> specs, bool enabled) {
    final sig = specs.map((s) => s.signature).join('\n');
    if (sig == state.signature) return;
    state = state.copyWith(signature: sig);
    _apply(specs, enabled);
  }

  Future<void> _apply(List<ReminderSpec> specs, bool enabled) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    final plan = planReminderReconciliation(
      specs: specs,
      current: state.scheduled,
      enabled: enabled,
      permissionGranted: await scheduler.permissionGranted(),
    );

    if (plan.clearAll) {
      await scheduler.cancelAll();
      state = state.copyWith(scheduled: const {});
      return;
    }

    for (final id in plan.cancelIds) {
      await scheduler.cancel(id);
    }
    for (final spec in plan.toSchedule) {
      if (spec.repeatsDaily) {
        await scheduler.scheduleDaily(spec);
      } else {
        await scheduler.scheduleOneShot(spec);
      }
    }
    state = state.copyWith(scheduled: plan.scheduled);
  }
}
