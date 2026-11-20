import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../domain/reconcile_reminders.dart';
import '../domain/reminder_spec.dart';
import 'reminder_scheduler_provider.dart';

/// Immutable snapshot of the live OS schedule. Exposed through Riverpod so
/// state is observable and testable instead of hidden in private fields.
class ReminderSyncState {
  const ReminderSyncState({
    this.signature,
    this.scheduled = const {},
    this.error,
  });

  /// Inputs that produced [scheduled]: specs, enabled flag and OS permission.
  final String? signature;
  final Map<int, String> scheduled;

  /// Last failed reconcile. Kept observable so a failure is never silent.
  final Object? error;

  ReminderSyncState copyWith({
    String? signature,
    Map<int, String>? scheduled,
    Object? error,
  }) {
    return ReminderSyncState(
      signature: signature ?? this.signature,
      scheduled: scheduled ?? this.scheduled,
      error: error,
    );
  }
}

/// Owns the live OS schedule: one signature guards no-op reconciles and the
/// scheduled-id map lets cancellations target only obsolete reminders. The
/// widget only computes the expected spec set and calls [sync].
final reminderSyncProvider = NotifierProvider<ReminderSync, ReminderSyncState>(
  ReminderSync.new,
);

class ReminderSync extends Notifier<ReminderSyncState> {
  /// Serializes reconciles so two rapid calls cannot interleave writes.
  Future<void> _tail = Future.value();

  @override
  ReminderSyncState build() => const ReminderSyncState();

  void initialize() {
    final scheduler = ref.read(reminderSchedulerProvider);
    unawaited(
      scheduler.initialize().then(
        (_) => scheduler.setNotificationTapHandler(handleTap),
        onError: (Object error, StackTrace stack) {
          debugPrint('Reminder scheduler init failed: $error\n$stack');
        },
      ),
    );
  }

  void handleTap(String? payload) {
    if (payload == null || payload == '/') return;
    ref.read(appRouterProvider).push(payload);
  }

  /// Reconciles the OS schedule to [specs]. The signature covers every input
  /// that can change the plan, and is only committed after a successful apply
  /// so a failed attempt is retried on the next call.
  Future<void> sync(List<ReminderSpec> specs, bool enabled) {
    final pending = _tail.then((_) => _reconcile(specs, enabled));
    _tail = pending;
    return pending;
  }

  Future<void> _reconcile(List<ReminderSpec> specs, bool enabled) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    try {
      final granted = await scheduler.permissionGranted();
      final sig =
          'enabled=$enabled;granted=$granted\n'
          '${specs.map((s) => s.signature).join('\n')}';
      if (sig == state.signature) return;

      final plan = planReminderReconciliation(
        specs: specs,
        current: state.scheduled,
        enabled: enabled,
        permissionGranted: granted,
      );

      if (plan.clearAll) {
        await scheduler.cancelAll();
        state = ReminderSyncState(signature: sig, scheduled: const {});
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
      state = ReminderSyncState(signature: sig, scheduled: plan.scheduled);
    } catch (error, stack) {
      debugPrint('Reminder reconcile failed: $error\n$stack');
      state = state.copyWith(error: error);
    }
  }
}
