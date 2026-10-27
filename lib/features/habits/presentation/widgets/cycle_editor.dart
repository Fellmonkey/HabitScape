import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_theme.dart';
import 'number_stepper.dart';

/// Mutable descriptor of a cycle frequency: length, active days, optional
/// per-day labels, and the optional start date.
class CycleConfig {
  const CycleConfig({
    required this.length,
    required this.days,
    required this.labels,
    this.startDate,
  });

  final int length;
  final Set<int> days;
  final Map<int, String> labels;
  final DateTime? startDate;

  CycleConfig copyWith({
    int? length,
    Set<int>? days,
    Map<int, String>? labels,
    DateTime? startDate,
  }) {
    return CycleConfig(
      length: length ?? this.length,
      days: days ?? this.days,
      labels: labels ?? this.labels,
      startDate: startDate ?? this.startDate,
    );
  }
}

/// Editors for a cycle frequency: length stepper, active-day chips, optional
/// per-day labels, and the start-date picker. Controlled — every change is
/// reported through [onChanged]; the parent owns the [CycleConfig].
class CycleEditor extends ConsumerWidget {
  const CycleEditor({required this.config, required this.onChanged, super.key});

  final CycleConfig config;
  final ValueChanged<CycleConfig> onChanged;

  void _changeLength(int value) {
    final days = config.days.where((d) => d <= value).toSet();
    if (days.isEmpty) days.add(1);
    onChanged(config.copyWith(length: value, days: days));
  }

  void _toggleDay(int day) {
    final selected = config.days.contains(day);
    final days = Set<int>.from(config.days);
    final labels = Map<int, String>.from(config.labels);
    if (selected) {
      if (days.length <= 1) return;
      days.remove(day);
      labels.remove(day);
    } else {
      days.add(day);
    }
    onChanged(config.copyWith(days: days, labels: labels));
  }

  void _setLabel(int day, String raw) {
    final labels = Map<int, String>.from(config.labels);
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      labels.remove(day);
    } else {
      labels[day] = trimmed;
    }
    onChanged(config.copyWith(labels: labels));
  }

  Future<void> _pickStartDate(BuildContext context, WidgetRef ref) async {
    final date = await showDatePicker(
      context: context,
      initialDate: config.startDate ?? ref.read(todayDateProvider),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date != null) onChanged(config.copyWith(startDate: date));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NumberStepper(
          label: 'Длина цикла: ${config.length} дн.',
          value: config.length,
          min: 2,
          max: 30,
          onChanged: _changeLength,
        ),
        Text('Активные дни цикла:', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(config.length, (index) {
            final day = index + 1;
            final selected = config.days.contains(day);
            return FilterChip(
              label: Text('$day'),
              selected: selected,
              onSelected: (_) => _toggleDay(day),
            );
          }),
        ),
        if (config.days.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Подписи к дням (опционально):',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ...(() {
            final sortedDays = config.days.toList()..sort();
            return sortedDays.map((day) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  key: ValueKey('cycle_label_$day'),
                  initialValue: config.labels[day] ?? '',
                  decoration: InputDecoration(
                    labelText: 'Подпись для дня $day',
                    border: OutlineInputBorder(borderRadius: AppRadius.borderS),
                    isDense: true,
                  ),
                  onChanged: (val) => _setLabel(day, val),
                ),
              );
            });
          })(),
        ],
        const SizedBox(height: 16),
        Text('Начало отсчета цикла:', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickStartDate(context, ref),
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
                  config.startDate == null
                      ? 'Дата создания (По умолчанию)'
                      : '${config.startDate!.day.toString().padLeft(2, '0')}.${config.startDate!.month.toString().padLeft(2, '0')}.${config.startDate!.year}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
