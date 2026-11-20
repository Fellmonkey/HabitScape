import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/features/reminders/domain/reconcile_reminders.dart';
import 'package:habitscape/features/reminders/domain/reminder_spec.dart';

ReminderSpec spec(int id, {int hour = 8}) {
  return ReminderSpec(
    id: id,
    title: 't',
    body: 'b',
    hour: hour,
    minute: 0,
    kind: ReminderKind.habit,
  );
}

void main() {
  group('planReminderReconciliation', () {
    test('disabled reminders drop the whole schedule', () {
      final plan = planReminderReconciliation(
        specs: [spec(1)],
        current: {1: spec(1).signature},
        enabled: false,
        permissionGranted: true,
      );
      expect(plan.clearAll, isTrue);
      expect(plan.toSchedule, isEmpty);
      expect(plan.scheduled, isEmpty);
    });

    test('missing permission drops the whole schedule', () {
      final plan = planReminderReconciliation(
        specs: [spec(1)],
        current: {1: spec(1).signature},
        enabled: true,
        permissionGranted: false,
      );
      expect(plan.clearAll, isTrue);
    });

    test('unchanged spec needs no platform work', () {
      final plan = planReminderReconciliation(
        specs: [spec(1)],
        current: {1: spec(1).signature},
        enabled: true,
        permissionGranted: true,
      );
      expect(plan.clearAll, isFalse);
      expect(plan.cancelIds, isEmpty);
      expect(plan.toSchedule, isEmpty);
    });

    test('obsolete ids are cancelled and new specs scheduled', () {
      final wanted = spec(2);
      final plan = planReminderReconciliation(
        specs: [wanted],
        current: {1: 'old'},
        enabled: true,
        permissionGranted: true,
      );
      expect(plan.cancelIds, [1]);
      expect(plan.toSchedule, [wanted]);
      expect(plan.scheduled, {2: wanted.signature});
    });

    test('a changed signature reschedules the same id', () {
      final changed = spec(1, hour: 9);
      final plan = planReminderReconciliation(
        specs: [changed],
        current: {1: spec(1).signature},
        enabled: true,
        permissionGranted: true,
      );
      expect(plan.cancelIds, [1]);
      expect(plan.toSchedule, [changed]);
    });

    test('daily vs one-shot is preserved for the executor', () {
      final oneShot = ReminderSpec(
        id: 3,
        title: 't',
        body: 'b',
        hour: 20,
        minute: 0,
        kind: ReminderKind.weekSummary,
        date: DateTime.utc(2026, 11, 22),
      );
      final plan = planReminderReconciliation(
        specs: [oneShot],
        current: const {},
        enabled: true,
        permissionGranted: true,
      );
      expect(plan.toSchedule.single.repeatsDaily, isFalse);
    });
  });
}
