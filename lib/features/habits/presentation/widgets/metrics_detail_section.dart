import 'package:flutter/material.dart';

import '../../domain/habit_engine.dart';

/// Raw metrics dump for the habit-detail "Метрики" tab — text rows, one per
/// metric, so every number is visible at a glance.
class MetricsDetailSection extends StatelessWidget {
  const MetricsDetailSection({required this.metrics, super.key});

  final HabitMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Метрики', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Выполнение: ${metrics.completionPct.toStringAsFixed(1)}%'),
        Text('Выполнено: ${metrics.absoluteCompletions}'),
        Text('Ожидалось: ${metrics.requiredBase}'),
        Text('Пропуски: ${metrics.skipCount}'),
        const SizedBox(height: 8),
        Text('Утро: ${(metrics.morningRatio * 100).round()}%'),
        Text('День: ${(metrics.afternoonRatio * 100).round()}%'),
        Text('Вечер: ${(metrics.eveningRatio * 100).round()}%'),
        Text('Ночь: ${(metrics.nightRatio * 100).round()}%'),
      ],
    );
  }
}
