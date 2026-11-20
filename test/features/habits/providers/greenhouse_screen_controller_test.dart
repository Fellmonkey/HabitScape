import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/features/habits/providers/greenhouse_screen_controller.dart';

void main() {
  test('celebrates the day only once, on the completion transition', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final vm = container.read(greenhouseScreenControllerProvider.notifier);
    final day = DateTime(2026, 11, 20);

    expect(
      vm.checkDayClosed(hasHabits: true, progress: 0.5, today: day),
      isFalse,
    );
    expect(
      vm.checkDayClosed(hasHabits: true, progress: 1.0, today: day),
      isTrue,
    );
    expect(
      vm.checkDayClosed(hasHabits: true, progress: 1.0, today: day),
      isFalse,
    );
  });

  test('toggle hint is claimed exactly once', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final vm = container.read(greenhouseScreenControllerProvider.notifier);

    expect(vm.claimToggleHint(canSeeToggle: false), isFalse);
    expect(vm.claimToggleHint(canSeeToggle: true), isTrue);
    expect(vm.claimToggleHint(canSeeToggle: true), isFalse);
  });
}
