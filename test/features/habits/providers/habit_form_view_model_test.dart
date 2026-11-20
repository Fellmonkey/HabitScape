import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitscape/domain/enums.dart';
import 'package:habitscape/domain/scheduling.dart';
import 'package:habitscape/features/habits/domain/habit_templates.dart';
import 'package:habitscape/features/habits/providers/habit_form_view_model.dart';

void main() {
  test('new-habit draft starts with defaults and can be edited', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = habitFormViewModelProvider(null);

    expect(container.read(provider).canSave, isFalse);
    final vm = container.read(provider.notifier);
    vm.setName('  Чтение  ');
    vm.setFrequency(FrequencyType.xPerWeek);
    vm.setXValue(4);

    final draft = container.read(provider);
    expect(draft.canSave, isTrue);
    expect(draft.buildFrequency(), isA<XPerWeekFrequency>());
    expect((draft.buildFrequency() as XPerWeekFrequency).x, 4);
  });

  test('templates replace the draft through one pure command', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = habitFormViewModelProvider(null);
    final template = habitTemplates.first;

    container.read(provider.notifier).applyTemplate(template);

    final draft = container.read(provider);
    expect(draft.name, template.name);
    expect(draft.icon, template.icon);
    expect(draft.timeOfDay, template.timeOfDay);
    expect(draft.buildFrequency(), isA<DailyFrequency>());
  });
}
