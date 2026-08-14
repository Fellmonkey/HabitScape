import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/sheet_handle.dart';
import '../../providers/habit_providers.dart';

/// Bottom sheet for editing the «Момент дня»: the most memorable moment
/// of today + the day mood (🟢 хорошо / 🟡 так себе / 🔴 плохо).
class DayMomentSheet extends ConsumerStatefulWidget {
  const DayMomentSheet({super.key, this.initial});

  /// Existing note to prefill (when editing today's note).
  final DayNote? initial;

  @override
  ConsumerState<DayMomentSheet> createState() => _DayMomentSheetState();
}

class _DayMomentSheetState extends ConsumerState<DayMomentSheet> {
  late final TextEditingController _momentController;
  DayMood? _mood;

  @override
  void initState() {
    super.initState();
    final note = widget.initial;
    _momentController = TextEditingController(text: note?.moment ?? '');
    _mood = note?.mood;
  }

  @override
  void dispose() {
    _momentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final moment = _momentController.text.trim();
    final actions = ref.read(habitActionsProvider.notifier);

    if (moment.isEmpty && _mood == null) {
      // Nothing to remember — clear the note entirely.
      await actions.clearDayNote();
    } else {
      await actions.saveDayNote(
        moment: moment.isEmpty ? null : moment,
        mood: _mood,
      );
    }

    if (mounted) {
      HapticFeedback.selectionClick();
      Navigator.pop(context);
    }
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
            const SizedBox(height: 16),
            Text(
              'Момент дня',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Что запомнилось сегодня?',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
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
            FilledButton(
              key: K.dayMomentSave,
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
              ),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
