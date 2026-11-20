import 'reminder_spec.dart';

/// Pure decision for bringing the OS schedule in line with the wanted specs.
/// The provider only executes the plan; no plugin or Riverpod leaks in here.
class ReminderReconciliationPlan {
  const ReminderReconciliationPlan({
    required this.clearAll,
    required this.cancelIds,
    required this.toSchedule,
    required this.scheduled,
  });

  final bool clearAll;
  final List<int> cancelIds;
  final List<ReminderSpec> toSchedule;
  final Map<int, String> scheduled;
}

/// Diffs [current] against [specs] using each spec's [ReminderSpec.signature].
///
/// Disabled or ungranted reminders drop the whole schedule. Otherwise ids no
/// longer wanted are cancelled, changed specs are re-scheduled, and unchanged
/// ones are left alone. [toSchedule] retains daily/one-shot information so the
/// executor can pick the right platform call.
ReminderReconciliationPlan planReminderReconciliation({
  required List<ReminderSpec> specs,
  required Map<int, String> current,
  required bool enabled,
  required bool permissionGranted,
}) {
  if (!enabled || !permissionGranted) {
    return const ReminderReconciliationPlan(
      clearAll: true,
      cancelIds: <int>[],
      toSchedule: <ReminderSpec>[],
      scheduled: <int, String>{},
    );
  }

  final wanted = {for (final spec in specs) spec.id};
  final cancelIds = <int>[];
  final next = Map<int, String>.from(current);

  for (final id in next.keys.toList()) {
    if (!wanted.contains(id)) {
      cancelIds.add(id);
      next.remove(id);
    }
  }

  final toSchedule = <ReminderSpec>[];
  for (final spec in specs) {
    if (next[spec.id] == spec.signature) continue;
    if (next.containsKey(spec.id)) cancelIds.add(spec.id);
    toSchedule.add(spec);
    next[spec.id] = spec.signature;
  }

  return ReminderReconciliationPlan(
    clearAll: false,
    cancelIds: List.unmodifiable(cancelIds),
    toSchedule: List.unmodifiable(toSchedule),
    scheduled: Map.unmodifiable(next),
  );
}
