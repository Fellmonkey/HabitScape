import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/domain/scheduling.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../domain/habit_templates.dart';
import '../../providers/habit_actions.dart';
import 'cycle_editor.dart';
import 'habit_template_strip.dart';
import 'icon_picker.dart';
import 'number_stepper.dart';
import 'weekday_chip_selector.dart';

class HabitFormSheet extends ConsumerStatefulWidget {
  const HabitFormSheet({super.key, this.habit});

  final Habit? habit;

  @override
  ConsumerState<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<HabitFormSheet> {
  late final TextEditingController _nameController;
  late FrequencyType _frequency;
  late TimeOfDay _timeOfDay;
  late HabitIcon _icon;
  late final Set<int> _selectedWeekdays;
  late int _xValue;
  late int _everyXDays;
  late CycleConfig _cycle;
  bool _advancedExpanded = false;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;

    if (h != null) {
      _nameController = TextEditingController(text: h.name);
      final frequency = HabitFrequency.fromHabit(h);
      _frequency = frequency.type;
      _timeOfDay = TimeOfDay.fromString(h.timeOfDay);
      _icon = HabitIcon.fromString(h.icon);
      _advancedExpanded = true; // editing: show every field up front

      _selectedWeekdays = switch (frequency) {
        WeekdaysFrequency(:final days) => days.toSet(),
        _ => {1, 2, 3, 4, 5},
      };
      final parsedX = frequency is XPerWeekFrequency
          ? frequency.x
          : frequency is EveryXDaysFrequency
          ? frequency.x
          : 1;
      _xValue = _frequency == FrequencyType.xPerWeek && parsedX > 1
          ? parsedX
          : 3;
      _everyXDays = _frequency == FrequencyType.everyXDays && parsedX > 1
          ? parsedX
          : 7;

      final cycle = frequency is CycleFrequency
          ? frequency
          : CycleFrequency(length: 5, days: const [1]);
      _cycle = CycleConfig(
        length: cycle.length,
        days: cycle.days.toSet(),
        labels: Map.from(cycle.labels),
        startDate: CycleFrequency.decodeStartDate(cycle.startDate),
      );
    } else {
      _nameController = TextEditingController();
      _frequency = FrequencyType.daily;
      _timeOfDay = TimeOfDay.anytime;
      _icon = HabitIcon.check;
      _selectedWeekdays = {1, 2, 3, 4, 5};
      _xValue = 3;
      _everyXDays = 7;
      _cycle = const CycleConfig(length: 5, days: {1}, labels: {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  HabitFrequency _buildFrequency() => switch (_frequency) {
    FrequencyType.weekdays => WeekdaysFrequency(
      _selectedWeekdays.toList()..sort(),
    ),
    FrequencyType.xPerWeek => XPerWeekFrequency(_xValue),
    FrequencyType.everyXDays => EveryXDaysFrequency(_everyXDays),
    FrequencyType.cycle => CycleFrequency(
      length: _cycle.length,
      days: _cycle.days.toList()..sort(),
      labels: _cycle.labels,
      startDate: CycleFrequency.encodeStartDate(_cycle.startDate),
    ),
    _ => const DailyFrequency(),
  };

  void _applyTemplate(HabitTemplate template) {
    setState(() {
      _nameController.text = template.name;
      _icon = template.icon;
      _frequency = template.frequency.type;
      _timeOfDay = template.timeOfDay;
      _advancedExpanded = false;
      switch (template.frequency) {
        case WeekdaysFrequency(:final days):
          _selectedWeekdays
            ..clear()
            ..addAll(days);
        case XPerWeekFrequency(:final x):
          _xValue = x < 1 ? 3 : x;
        case EveryXDaysFrequency(:final x):
          _everyXDays = x < 2 ? 7 : x;
        case CycleFrequency frequency:
          _cycle = _cycle.copyWith(
            length: frequency.length,
            days: frequency.days.toSet(),
            labels: Map.from(frequency.labels),
          );
        case DailyFrequency():
          break;
      }
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final frequency = _buildFrequency();
    final actions = ref.read(habitActionsProvider.notifier);

    if (_isEdit) {
      await actions.updateHabit(
        habitId: widget.habit!.id,
        name: name,
        icon: _icon,
        frequency: frequency,
        timeOfDay: _timeOfDay,
      );
      if (mounted) Navigator.pop(context);
    } else {
      final id = await actions.createHabit(
        name: name,
        icon: _icon,
        frequency: frequency,
        timeOfDay: _timeOfDay,
      );
      if (mounted) Navigator.pop(context, id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: _isEdit ? 0.8 : 0.6,
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
              _isEdit ? 'Редактировать' : 'Новая привычка',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),

            // ── Templates (new habits only) ──
            if (!_isEdit)
              HabitTemplateStrip(
                onApply: (t) => setState(() => _applyTemplate(t)),
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
                  .map((t) => _freqChip(t.localizedName, t))
                  .toList(),
            ),
            const SizedBox(height: 8),

            if (_frequency == FrequencyType.weekdays)
              WeekdayChipSelector(
                selected: _selectedWeekdays,
                onChanged: (next) => setState(
                  () => _selectedWeekdays
                    ..clear()
                    ..addAll(next),
                ),
              ),
            if (_frequency == FrequencyType.xPerWeek)
              NumberStepper(
                label: '$_xValue раз в неделю',
                value: _xValue,
                min: 1,
                max: 7,
                onChanged: (v) => setState(() => _xValue = v),
              ),
            if (_frequency == FrequencyType.everyXDays)
              NumberStepper(
                label: everyXDaysLabel(_everyXDays),
                value: _everyXDays,
                min: 2,
                max: 30,
                onChanged: (v) => setState(() => _everyXDays = v),
              ),
            if (_frequency == FrequencyType.cycle)
              CycleEditor(
                config: _cycle,
                onChanged: (c) => setState(() => _cycle = c),
              ),
            const SizedBox(height: 8),

            // ── Optional settings (time, icon) ──
            // Hidden by default: a new habit needs a name and a frequency.
            // Everything else has a sensible default.
            ExpansionTile(
              initiallyExpanded: _advancedExpanded,
              onExpansionChanged: (v) => _advancedExpanded = v,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text('Настроить', style: theme.textTheme.labelLarge),
              subtitle: Text(
                '${_timeOfDay.localizedName} · ${_icon.visual.label}',
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
                        selected: _timeOfDay == t,
                        onSelected: (_) => setState(() => _timeOfDay = t),
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
                  selected: _icon,
                  onSelected: (ic) => setState(() => _icon = ic),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Save Button ──
            FilledButton(
              key: K.habitCreateButton,
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
              ),
              child: Text(_isEdit ? 'Сохранить' : 'Создать'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _freqChip(String label, FrequencyType type) {
    return ChoiceChip(
      label: Text(label),
      selected: _frequency == type,
      onSelected: (_) => setState(() => _frequency = type),
    );
  }
}
