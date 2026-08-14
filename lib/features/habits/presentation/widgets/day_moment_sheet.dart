import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../providers/habit_providers.dart';

/// Bottom sheet for editing the «Момент дня»: the most memorable moment
/// of a day + the day mood (🟢 хорошо / 🟡 так себе / 🔴 плохо).
class DayMomentSheet extends ConsumerStatefulWidget {
  const DayMomentSheet({super.key, this.initial, this.dateTimestamp});

  /// Existing note to prefill (when editing an existing note).
  final DayNote? initial;

  /// The date (unix midnight) this note belongs to. Defaults to today.
  final int? dateTimestamp;

  @override
  ConsumerState<DayMomentSheet> createState() => _DayMomentSheetState();
}

class _DayMomentSheetState extends ConsumerState<DayMomentSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _momentController;
  late final AnimationController _saveController;
  late final Animation<double> _saveScale;
  DayMood? _mood;

  @override
  void initState() {
    super.initState();
    final note = widget.initial;
    _momentController = TextEditingController(text: note?.moment ?? '');
    _mood = note?.mood;

    // "Juicy" save animation: a quick squash-and-stretch of the button.
    _saveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _saveScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.06), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _saveController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _momentController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final moment = _momentController.text.trim();
    final actions = ref.read(habitActionsProvider.notifier);
    final ts = widget.dateTimestamp ?? todayTimestamp();

    if (moment.isEmpty && _mood == null) {
      // Nothing to remember — clear the note entirely.
      await actions.clearDayNote(ts);
    } else {
      await actions.saveDayNote(
        dateTimestamp: ts,
        moment: moment.isEmpty ? null : moment,
        mood: _mood,
      );
    }

    if (mounted) {
      Haptics.tap(ref.read(hapticsEnabledProvider));
      _saveController.forward(from: 0);
      // Let the squish finish before closing the sheet.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) Navigator.pop(context);
    }
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _DayMomentHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40), // balance the help button
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Момент дня',
                        style: theme.textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.dateTimestamp == null
                            ? 'Что запомнилось сегодня?'
                            : 'Что запомнилось в этот день?',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: K.dayMomentHelp,
                  tooltip: 'Зачем это нужно',
                  onPressed: _showHelp,
                  icon: Icon(
                    Icons.help_outline_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: K.dayMomentField,
              controller: _momentController,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Например: встретил друга, гулял у залива…',
                border: OutlineInputBorder(borderRadius: AppRadius.borderM),
              ),
            ),
            const SizedBox(height: 8),
            Text('Как прошёл день?', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: DayMood.values.map((mood) {
                final selected = _mood == mood;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      avatar: CircleAvatar(
                        backgroundColor: mood.color,
                        radius: 6,
                      ),
                      label: Text(mood.localizedName),
                      selected: selected,
                      onSelected: (_) => setState(() => _mood = mood),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _saveScale,
              child: FilledButton(
                key: K.dayMomentSave,
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderM,
                  ),
                ),
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Short «why» sheet — the essence of the «Момент дня» idea.
class _DayMomentHelpSheet extends StatelessWidget {
  const _DayMomentHelpSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          Text('Зачем это нужно', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(
            'Это вечерний ритуал на 3 минуты — он превращает прожитые дни '
            'из «ещё одного вторника» в дни, которые ты помнишь.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _HelpItem(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.sageGreen,
            title: 'Одна строка о дне',
            text:
                'Прокрути день в голове и запиши самое запоминающееся: '
                'встречу, разговор, событие. Без оценок — просто факт.',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            icon: Icons.palette_outlined,
            color: AppColors.warmAmber,
            title: 'Цвет настроения',
            text:
                '🟢 день был хорошим · 🟡 так себе · 🔴 плохим. '
                'Через месяц ты увидишь, как прошёл месяц, не листая.',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            icon: Icons.memory_rounded,
            color: AppColors.softLavender,
            title: 'Память на годы',
            text:
                'Через год ты сможешь открыть любой день и вспомнить, что '
                'было вокруг него. Дни перестанут сливаться.',
          ),
        ],
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(text, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
