import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/router/app_router.dart';
import '../domain/reminder_spec.dart';

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
    final current = Map<int, String>.from(state.scheduled);
    if (!enabled || !await scheduler.permissionGranted()) {
      await scheduler.cancelAll();
      state = state.copyWith(scheduled: const {});
      return;
    }

    final wanted = {for (final spec in specs) spec.id};
    for (final id in current.keys.toList()) {
      if (!wanted.contains(id)) {
        await scheduler.cancel(id);
        current.remove(id);
      }
    }
    for (final spec in specs) {
      if (current[spec.id] == spec.signature) continue;
      if (current.containsKey(spec.id)) await scheduler.cancel(spec.id);
      if (spec.repeatsDaily) {
        await scheduler.scheduleDaily(spec);
      } else {
        await scheduler.scheduleOneShot(spec);
      }
      current[spec.id] = spec.signature;
    }
    state = state.copyWith(scheduled: Map.unmodifiable(current));
  }
}
