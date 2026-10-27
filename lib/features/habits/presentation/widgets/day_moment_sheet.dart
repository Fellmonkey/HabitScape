import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../domain/day_moment_draft.dart';
import '../../providers/day_note_providers.dart';

/// Bottom sheet for editing the day moment: the memorable moment of a
/// day + the day mood (🟢 good / 🟡 so-so / 🔴 bad).
///
/// The single source for the existing note is the [dayNoteProvider] seam —
/// never a direct DAO read and never a caller-passed copy.
class DayMomentSheet extends ConsumerStatefulWidget {
  const DayMomentSheet({super.key, this.dateTimestamp});

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
  late DayMomentDraft _draft;

  /// The stream-provided note was already applied to the draft once.
  bool _noteApplied = false;

  @override
  void initState() {
    super.initState();
    _draft = DayMomentDraft.fromNote(null);
    _momentController = TextEditingController(text: _draft.moment);
    _momentController.addListener(_syncMoment);

    // "Juicy" save animation: a quick squash-and-stretch of the button.
    _saveController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _saveScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.06), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(
            parent: _saveController,
            curve: AppMotion.easeOutStrong,
          ),
        );
  }

  @override
  void dispose() {
    _momentController.removeListener(_syncMoment);
    _momentController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  void _syncMoment() {
    setState(() => _draft = _draft.withMoment(_momentController.text));
  }

  /// Applies the provider-loaded note once, on the first resolution. The
  /// provider is the sheet's only read path — no direct DAO access.
  void _applyLoadedNote(DayNote? note) {
    if (_noteApplied) return;
    _noteApplied = true;
    final draft = DayMomentDraft.fromNote(note);
    _draft = draft;
    _momentController.text = draft.moment;
  }

  Future<void> _save() async {
    final actions = ref.read(dayNoteActionsProvider.notifier);
    final ts = widget.dateTimestamp ?? ref.read(todayProvider);

    await actions.saveDayMoment(_draft, dateTimestamp: ts);

    if (mounted) {
      Haptics.tap(ref.read(hapticsEnabledProvider));
      _saveController.forward(from: 0);
      await Future<void>.delayed(
        const Duration(milliseconds: 200),
      ); // let the squish finish
      if (mounted) Navigator.pop(context);
    }
  }

  void _showHelp() {
    AppSheets.show<void>(
      context,
      builder: (ctx) => const _DayMomentHelpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Load the existing note through the provider seam (never a direct DAO
    // read). Today's sheet defaults to today and loads the same way.
    if (widget.dateTimestamp != null) {
      ref
          .watch(dayNoteProvider(widget.dateTimestamp!))
          .whenData(_applyLoadedNote);
    }

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
              autofocus: true,
              maxLines: 3,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
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
                final selected = _draft.mood == mood;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      avatar: CircleAvatar(
                        backgroundColor: mood.color(context),
                        radius: 6,
                      ),
                      label: Text(mood.localizedName),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _draft = _draft.toggleMood(mood)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _saveScale,
              child: PressableScale(
                child: FilledButton(
                  key: K.dayMomentSave,
                  onPressed: _draft.canSave ? _save : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.borderM,
                    ),
                  ),
                  child: const Text('Сохранить'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Short "why" sheet — the essence of the day-moment idea.
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
            'Это вечерний ритуал на 15 секунд — он превращает прожитые дни '
            'из «ещё одного вторника» в дни, которые ты помнишь.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _HelpItem(
            icon: Icons.auto_awesome_rounded,
            color: context.palette.sage,
            title: 'Одна строка о дне',
            text:
                'Прокрути день в голове и запиши самое запоминающееся: '
                'встречу, разговор, событие. Без оценок — просто факт.',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            icon: Icons.palette_outlined,
            color: context.palette.amber,
            title: 'Цвет настроения',
            text:
                '🟢 день был хорошим · 🟡 так себе · 🔴 плохим. '
                'Через месяц ты увидишь, как прошёл месяц, не листая.',
          ),
          const SizedBox(height: 12),
          _HelpItem(
            icon: Icons.memory_rounded,
            color: context.palette.lavender,
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

/// Short help row: icon + title + description.
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
