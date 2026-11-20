import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/reminder_scheduler.dart';
import '../../../core/router/app_router.dart';
import '../domain/reminder_spec.dart';

/// Owns the live OS schedule: a single signature guards no-op reconciles and
/// the scheduled-id map lets cancellations target only obsolete reminders.
/// The widget only computes the expected spec set and calls [sync].
final reminderSyncProvider = NotifierProvider<ReminderSync, void>(
  ReminderSync.new,
);

class ReminderSync extends Notifier<void> {
  @override
  void build() {}

  String? _signature;
  final Map<int, String> _scheduled = {};

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
    if (sig == _signature) return;
    _signature = sig;
    _apply(specs, enabled);
  }

  Future<void> _apply(List<ReminderSpec> specs, bool enabled) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    if (!enabled || !await scheduler.permissionGranted()) {
      await scheduler.cancelAll();
      _scheduled.clear();
      return;
    }

    final wanted = {for (final spec in specs) spec.id};
    for (final id in _scheduled.keys.toList()) {
      if (!wanted.contains(id)) {
        await scheduler.cancel(id);
        _scheduled.remove(id);
      }
    }
    for (final spec in specs) {
      if (_scheduled[spec.id] == spec.signature) continue;
      if (_scheduled.containsKey(spec.id)) await scheduler.cancel(spec.id);
      if (spec.repeatsDaily) {
        await scheduler.scheduleDaily(spec);
      } else {
        await scheduler.scheduleOneShot(spec);
      }
      _scheduled[spec.id] = spec.signature;
    }
  }
}
