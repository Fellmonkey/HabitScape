import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/domain/enums.dart';
import 'package:habitscape/features/habits/providers/habit_card_controller.dart';

void main() {
  test('optimistic status and undo window are owned by the ViewModel', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = habitCardControllerProvider(7);
    final vm = container.read(provider.notifier);

    vm.beginApply(LogStatus.done, LogStatus.skip);
    var state = container.read(provider);
    expect(state.optimisticDone, isTrue);
    expect(state.undoOpen, isTrue);
    expect(state.undoPrevious, LogStatus.skip);

    vm.closeUndo();
    state = container.read(provider);
    expect(state.undoOpen, isFalse);
    expect(state.undoPrevious, isNull);
  });

  test('failed write rolls the optimistic status back', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = habitCardControllerProvider(7);

    container
        .read(provider.notifier)
        .beginApply(LogStatus.skip, LogStatus.done);
    container.read(provider.notifier).failApply();

    final state = container.read(provider);
    expect(state.optimisticDone, isFalse);
    expect(state.undoOpen, isFalse);
  });
}
