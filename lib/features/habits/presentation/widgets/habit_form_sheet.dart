import 'dart:convert';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/theme/app_theme.dart';
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
  late SeedArchetype _archetype;
  late final Set<int> _selectedWeekdays;
  late int _xValue;
  late int _everyXDays;
  late int _cycleLength;
  late final Set<int> _cycleDays;
  late final Map<int, String> _cycleLabels;
  DateTime? _cycleStartDate;

  bool get _isEdit => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    
    if (h != null) {
      _nameController = TextEditingController(text: h.name);
      _frequency = FrequencyType.fromString(h.frequencyType);
      _timeOfDay = TimeOfDay.fromString(h.timeOfDay);
      _archetype = SeedArchetype.fromString(h.seedArchetype);
      
      _selectedWeekdays = parseWeekdays(h.frequencyValue).toSet();
      final parsedX = parseXValue(h.frequencyValue);
      _xValue = _frequency == FrequencyType.xPerWeek && parsedX > 1 ? parsedX : 3;
      _everyXDays = _frequency == FrequencyType.everyXDays && parsedX > 1 ? parsedX : 7;

      final cycle = parseCycle(h.frequencyValue);
      _cycleLength = cycle.length;
      _cycleDays = cycle.days.toSet();
      _cycleLabels = Map.from(cycle.labels);
      if (cycle.startDate != null) {
        _cycleStartDate = DateTime.fromMillisecondsSinceEpoch(cycle.startDate! * 1000, isUtc: true).toLocal();
      }
    } else {
      _nameController = TextEditingController();
      _frequency = FrequencyType.daily;
      _timeOfDay = TimeOfDay.anytime;
      _archetype = SeedArchetype.oak;
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

  String _buildFrequencyValue() => switch (_frequency) {
        FrequencyType.weekdays =>
          jsonEncode({'days': _selectedWeekdays.toList()..sort()}),
        FrequencyType.xPerWeek => jsonEncode({'x': _xValue}),
        FrequencyType.everyXDays => jsonEncode({'x': _everyXDays}),
        FrequencyType.cycle => jsonEncode({
            'length': _cycleLength,
            'days': _cycleDays.toList()..sort(),
            'labels': _cycleLabels.map((k, v) => MapEntry(k.toString(), v)),
            if (_cycleStartDate != null)
              'startDate': DateTime(_cycleStartDate!.year, _cycleStartDate!.month, _cycleStartDate!.day).millisecondsSinceEpoch ~/ 1000,
          }),
        _ => '{}',
      };

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final freqValue = _buildFrequencyValue();
    final actions = ref.read(habitActionsProvider.notifier);

    if (_isEdit) {
      await actions.updateHabit(
        habitId: widget.habit!.id,
        name: name,
        seedArchetype: _archetype,
        frequencyType: _frequency,
        frequencyValue: freqValue,
        timeOfDay: _timeOfDay,
      );
    } else {
      actions.createHabit(
        name: name,
        category: 'general',
        seedArchetype: _archetype,
        frequencyType: _frequency,
        frequencyValue: freqValue,
        timeOfDay: _timeOfDay,
      );
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: _isEdit ? 0.75 : 0.65,
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
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: AppRadius.borderS,
                ),
              ),
            ),
            Text(_isEdit ? 'Редактировать' : 'Новая привычка', 
                 style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),

            // ── Name ──
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(borderRadius: AppRadius.borderM),
              ),
            ),
            const SizedBox(height: 16),

            // ── Time of Day ──
            Text('Время дня', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TimeOfDay.values.map((t) {
                return ChoiceChip(
                  label: Text(t.localizedName),
                  selected: _timeOfDay == t,
                  onSelected: (_) => setState(() => _timeOfDay = t),
                );
              }).toList(),
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

            if (_frequency == FrequencyType.weekdays) ..._buildWeekdaySelector(theme),
            if (_frequency == FrequencyType.xPerWeek) ..._buildXStepper(
              theme,
              label: '$_xValue раз в неделю',
              value: _xValue,
              min: 1,
              max: 7,
              onChanged: (v) => setState(() => _xValue = v),
            ),
            if (_frequency == FrequencyType.everyXDays) ..._buildXStepper(
              theme,
              label: 'Каждые $_everyXDays дней',
              value: _everyXDays,
              min: 2,
              max: 30,
              onChanged: (v) => setState(() => _everyXDays = v),
            ),
            if (_frequency == FrequencyType.cycle) ..._buildCycleSelector(theme),
            const SizedBox(height: 8),

            // ── Seed Archetype ──
            Text('Семечко (растение)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: SeedArchetype.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final arch = SeedArchetype.values[i];
                  final selected = _archetype == arch;
                  return GestureDetector(
                    onTap: () => setState(() => _archetype = arch),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.colorScheme.surface,
                        borderRadius: AppRadius.borderM,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.12),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            arch.icon,
                            color: selected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            arch.displayName,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Save Button ──
            FilledButton(
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
      (1, 'Пн'), (2, 'Вт'), (3, 'Ср'), (4, 'Чт'),
      (5, 'Пт'), (6, 'Сб'), (7, 'Вс'),
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
                if (_selectedWeekdays.length > 1) _selectedWeekdays.remove(r.$1);
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
        Text('Подписи к дням (опционально):', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        ...(() {
          final sortedDays = _cycleDays.toList()..sort();
          return sortedDays.map((day) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: TextEditingController(text: _cycleLabels[day] ?? ''),
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
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            borderRadius: AppRadius.borderS,
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
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
            child: Text(label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium),
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
