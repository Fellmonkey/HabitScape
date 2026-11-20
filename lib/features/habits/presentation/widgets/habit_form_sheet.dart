import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../domain/enums.dart';
import '../../../../domain/models/entities.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../providers/habit_actions.dart';
import '../../providers/habit_form_view_model.dart';
import 'cycle_editor.dart';
import 'habit_template_strip.dart';
import 'icon_picker.dart';
import 'number_stepper.dart';
import 'weekday_chip_selector.dart';

/// Create/edit sheet. All editable state lives in `HabitFormViewModel`; this
/// widget only renders its snapshot and dispatches commands.
class HabitFormSheet extends ConsumerStatefulWidget {
  const HabitFormSheet({super.key, this.habit});

  final Habit? habit;

  @override
  ConsumerState<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<HabitFormSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(habitFormViewModelProvider(widget.habit)).name,
    );
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() =>
      ref.read(habitFormViewModelProvider(widget.habit).notifier).setName(
        _nameController.text,
      );

  Future<void> _save() async {
    final draft = ref.read(habitFormViewModelProvider(widget.habit));
    if (!draft.canSave) return;

    final name = draft.name.trim();
    final frequency = draft.buildFrequency();
    final actions = ref.read(habitActionsProvider.notifier);

    if (widget.habit != null) {
      await actions.updateHabit(
        habitId: widget.habit!.id,
        name: name,
        icon: draft.icon,
        frequency: frequency,
        timeOfDay: draft.timeOfDay,
      );
      if (mounted) Navigator.pop(context);
    } else {
      final id = await actions.createHabit(
        name: name,
        icon: draft.icon,
        frequency: frequency,
        timeOfDay: draft.timeOfDay,
      );
      if (mounted) Navigator.pop(context, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(habitFormViewModelProvider(widget.habit));
    final vm = ref.read(habitFormViewModelProvider(widget.habit).notifier);
    final isEdit = widget.habit != null;

    return DraggableScrollableSheet(
      initialChildSize: isEdit ? 0.8 : 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: SheetHandle(),
            ),
            Text(
              isEdit ? 'Редактировать' : 'Новая привычка',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),

            // ── Templates (new habits only) ──
            if (!isEdit)
              HabitTemplateStrip(
                onApply: (t) {
                  vm.applyTemplate(t);
                  _nameController.text = t.name;
                },
              ),

            TextField(
              key: K.habitNameField,
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(borderRadius: AppRadius.borderM),
              ),
            ),
            const SizedBox(height: 16),

            // ── Frequency ──
            Text('Частота', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FrequencyType.values
                  .map(
                    (t) => ChoiceChip(
                      label: Text(t.localizedName),
                      selected: draft.frequency == t,
                      onSelected: (_) => vm.setFrequency(t),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            if (draft.frequency == FrequencyType.weekdays)
              WeekdayChipSelector(
                selected: draft.weekdays,
                onChanged: vm.setWeekdays,
              ),
            if (draft.frequency == FrequencyType.xPerWeek)
              NumberStepper(
                label: '${draft.xValue} раз в неделю',
                value: draft.xValue,
                min: 1,
                max: 7,
                onChanged: vm.setXValue,
              ),
            if (draft.frequency == FrequencyType.everyXDays)
              NumberStepper(
                label: everyXDaysLabel(draft.everyXDays),
                value: draft.everyXDays,
                min: 2,
                max: 30,
                onChanged: vm.setEveryXDays,
              ),
            if (draft.frequency == FrequencyType.cycle)
              CycleEditor(config: draft.cycle, onChanged: vm.setCycle),
            const SizedBox(height: 8),

            // ── Optional settings (time, icon) ──
            ExpansionTile(
              initiallyExpanded: draft.advancedExpanded,
              onExpansionChanged: vm.setAdvancedExpanded,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text('Настроить', style: theme.textTheme.labelLarge),
              subtitle: Text(
                '${draft.timeOfDay.localizedName} · ${draft.icon.visual.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Время дня', style: theme.textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: TimeOfDay.values.map((t) {
                      return ChoiceChip(
                        label: Text(t.localizedName),
                        selected: draft.timeOfDay == t,
                        onSelected: (_) => vm.setTimeOfDay(t),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Иконка', style: theme.textTheme.labelLarge),
                ),
                const SizedBox(height: 8),
                IconPicker(
                  selected: draft.icon,
                  onSelected: vm.setIcon,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Save Button ──
            FilledButton(
              key: K.habitCreateButton,
              onPressed: draft.canSave ? _save : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
              ),
              child: Text(isEdit ? 'Сохранить' : 'Создать'),
            ),
          ],
        ),
      ),
    );
  }
}
