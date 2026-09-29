import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import 'icon_picker.dart';
import '../../domain/habit_templates.dart';
import '../../domain/scheduling.dart';
import '../../providers/habit_providers.dart';

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
  late int _cycleLength;
  late final Set<int> _cycleDays;
  late final Map<int, String> _cycleLabels;
  DateTime? _cycleStartDate;
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
      _cycleLength = cycle.length;
      _cycleDays = cycle.days.toSet();
      _cycleLabels = Map.from(cycle.labels);
      if (cycle.startDate != null) {
        _cycleStartDate = DateTime.fromMillisecondsSinceEpoch(
          cycle.startDate! * 1000,
          isUtc: true,
        ).toLocal();
      }
    } else {
      _nameController = TextEditingController();
      _frequency = FrequencyType.daily;
      _timeOfDay = TimeOfDay.anytime;
      _icon = HabitIcon.check;
      _selectedWeekdays = {1, 2, 3, 4, 5};
      _xValue = 3;
      _everyXDays = 7;
      _cycleLength = 5;
      _cycleDays = {1};
      _cycleLabels = {};
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
      length: _cycleLength,
      days: _cycleDays.toList()..sort(),
      labels: _cycleLabels,
      startDate: _cycleStartDate == null
          ? null
          : DateTime(
                  _cycleStartDate!.year,
                  _cycleStartDate!.month,
                  _cycleStartDate!.day,
                ).millisecondsSinceEpoch ~/
                1000,
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
          _cycleLength = frequency.length;
          _cycleDays
            ..clear()
            ..addAll(frequency.days);
          _cycleLabels
            ..clear()
            ..addAll(frequency.labels);
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
        category: 'general',
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

            // ── Name ──
            if (!_isEdit) ...[
              Text('Шаблоны', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: habitTemplates.map((t) {
                  return ActionChip(
                    avatar: Icon(t.icon.icon, size: 16),
                    label: Text(t.name),
                    onPressed: () => _applyTemplate(t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

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
              ..._buildWeekdaySelector(theme),
            if (_frequency == FrequencyType.xPerWeek)
              ..._buildXStepper(
                theme,
                label: '$_xValue раз в неделю',
                value: _xValue,
                min: 1,
                max: 7,
                onChanged: (v) => setState(() => _xValue = v),
              ),
            if (_frequency == FrequencyType.everyXDays)
              ..._buildXStepper(
                theme,
                label: 'Каждые $_everyXDays дней',
                value: _everyXDays,
                min: 2,
                max: 30,
                onChanged: (v) => setState(() => _everyXDays = v),
              ),
            if (_frequency == FrequencyType.cycle)
              ..._buildCycleSelector(theme),
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
                '${_timeOfDay.localizedName} · ${_icon.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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

  List<Widget> _buildWeekdaySelector(ThemeData theme) {
    const days = [
      (1, 'Пн'),
      (2, 'Вт'),
      (3, 'Ср'),
      (4, 'Чт'),
      (5, 'Пт'),
      (6, 'Сб'),
      (7, 'Вс'),
    ];
    return [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: days.map(((int n, String label) r) {
          final selected = _selectedWeekdays.contains(r.$1);
          return FilterChip(
            label: Text(r.$2),
            selected: selected,
            onSelected: (_) => setState(() {
              if (selected) {
                if (_selectedWeekdays.length > 1) {
                  _selectedWeekdays.remove(r.$1);
                }
              } else {
                _selectedWeekdays.add(r.$1);
              }
            }),
          );
        }).toList(),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildCycleSelector(ThemeData theme) {
    return [
      _buildXStepper(
        theme,
        label: 'Длина цикла: $_cycleLength дн.',
        value: _cycleLength,
        min: 2,
        max: 30,
        onChanged: (v) => setState(() {
          _cycleLength = v;
          _cycleDays.removeWhere((day) => day > _cycleLength);
          if (_cycleDays.isEmpty) _cycleDays.add(1);
        }),
      ).first,
      const SizedBox(height: 8),
      Text('Активные дни цикла:', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(_cycleLength, (index) {
          final day = index + 1;
          final selected = _cycleDays.contains(day);
          return FilterChip(
            label: Text('$day'),
            selected: selected,
            onSelected: (_) => setState(() {
              if (selected) {
                if (_cycleDays.length > 1) {
                  _cycleDays.remove(day);
                  _cycleLabels.remove(day);
                }
              } else {
                _cycleDays.add(day);
              }
            }),
          );
        }),
      ),
      if (_cycleDays.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          'Подписи к дням (опционально):',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        ...(() {
          final sortedDays = _cycleDays.toList()..sort();
          return sortedDays.map((day) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextFormField(
                key: ValueKey('cycle_label_$day'),
                initialValue: _cycleLabels[day] ?? '',
                decoration: InputDecoration(
                  labelText: 'Подпись для дня $day',
                  border: OutlineInputBorder(borderRadius: AppRadius.borderS),
                  isDense: true,
                ),
                onChanged: (val) {
                  if (val.trim().isEmpty) {
                    _cycleLabels.remove(day);
                  } else {
                    _cycleLabels[day] = val.trim();
                  }
                },
              ),
            );
          });
        })(),
      ],
      const SizedBox(height: 16),
      Text('Начало отсчета цикла:', style: theme.textTheme.bodyMedium),
      const SizedBox(height: 8),
      InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _cycleStartDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            setState(() => _cycleStartDate = date);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            borderRadius: AppRadius.borderS,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _cycleStartDate == null
                    ? 'Дата создания (По умолчанию)'
                    : '${_cycleStartDate!.day.toString().padLeft(2, '0')}.${_cycleStartDate!.month.toString().padLeft(2, '0')}.${_cycleStartDate!.year}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildXStepper(
    ThemeData theme, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];
  }
}
