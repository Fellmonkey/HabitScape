import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/enums.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/settings/hintful.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/enum_visuals.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../../onboarding/app_tours.dart';
import '../../domain/day_moment_draft.dart';
import '../../providers/day_note_providers.dart';

/// Inline composer: type a line, tap a mood, save. Three actions, ~15 sec.
class DayMomentComposer extends ConsumerStatefulWidget {
  const DayMomentComposer({super.key, required this.initial});

  final DayNote? initial;

  @override
  ConsumerState<DayMomentComposer> createState() => _DayMomentComposerState();
}

class _DayMomentComposerState extends ConsumerState<DayMomentComposer> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  late DayMomentDraft _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = DayMomentDraft.fromNote(widget.initial);
    _controller = TextEditingController(text: _draft.moment);
    _controller.addListener(_refresh);
    // First launch belongs to the tour. Once it is seen, the field opens
    // itself so the evening ritual starts typing without a tap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _autofocusIfReady());
  }

  Future<void> _autofocusIfReady() async {
    if (!mounted || _controller.text.isNotEmpty) return;
    final store = await ref.read(hintfulStoreProvider.future);
    if (!mounted || _controller.text.isNotEmpty || _focusNode.hasFocus) return;
    // Autofocus only once the greenhouse tour has been seen (recorded in the
    // hintful store). `shouldShow` is the inverse: true = not seen yet.
    if (store.shouldShow(AppTourIds.greenhouse)) return;
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _draft = _draft.withMoment(_controller.text));
  }

  bool get _canSave => _draft.canSave;

  Future<void> _save() async {
    if (_saving || !_canSave) return;
    setState(() => _saving = true);

    await ref.read(dayNoteActionsProvider.notifier).saveDayMoment(_draft);

    if (!mounted) return;
    Haptics.tap(ref.read(hapticsEnabledProvider));
    _focusNode.unfocus();
    setState(() {
      _saving = false;
      _draft = _draft.markPersisted();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final border = OutlineInputBorder(
      borderRadius: AppRadius.borderS,
      borderSide: BorderSide(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
      ),
    );

    return Material(
      key: K.dayMomentCard,
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.borderL,
      child: InkWell(
        borderRadius: AppRadius.borderL,
        onTap: () {
          if (!_focusNode.hasFocus) _focusNode.requestFocus();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Момент дня',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      key: K.dayMomentField,
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 1,
                      maxLength: 200,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Что запомнилось сегодня?',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: theme.colorScheme.onSurface.withValues(
                          alpha: 0.04,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border.copyWith(
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton.filled(
                      key: K.dayMomentSave,
                      tooltip: 'Сохранить',
                      onPressed: _canSave && !_saving ? _save : null,
                      icon: const Icon(Icons.check_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final mood in DayMood.values) ...[
                    if (mood != DayMood.values.first) const SizedBox(width: 8),
                    Expanded(
                      child: MoodChoice(
                        mood: mood,
                        selected: _draft.mood == mood,
                        onTap: () =>
                            setState(() => _draft = _draft.toggleMood(mood)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the three mood buttons in the inline composer.
class MoodChoice extends StatelessWidget {
  const MoodChoice({
    required this.mood,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final DayMood mood;
  final bool selected;
  final VoidCallback onTap;

  String get _shortLabel => switch (mood) {
    DayMood.good => 'Хорошо',
    DayMood.ok => 'Так себе',
    DayMood.bad => 'Плохо',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      key: K.dayMomentMood(mood.name),
      borderRadius: AppRadius.borderS,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: mood.color.withValues(alpha: selected ? 0.22 : 0.08),
          borderRadius: AppRadius.borderS,
          border: Border.all(
            color: mood.color.withValues(alpha: selected ? 0.9 : 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: mood.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _shortLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? mood.color : theme.colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
