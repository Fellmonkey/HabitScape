import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/haptics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../domain/capsule.dart';
import '../../providers/letter_providers.dart';

/// Fullscreen letter: what you wrote to yourself, shown on the day it opened.
///
/// Opening a letter marks it as read. You can leave a short written reply
/// right here — it is stored on the letter, not framed as a goal or a task.
/// «Создать новую капсулу» closes the letter and opens a fresh composer.
class LetterScreen extends ConsumerStatefulWidget {
  const LetterScreen({super.key, required this.capsule});

  final Letter capsule;

  @override
  ConsumerState<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends ConsumerState<LetterScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markOpened());
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _markOpened() async {
    if (!mounted || widget.capsule.isOpened) return;
    final actions = ref.read(letterActionsProvider.notifier);
    await actions.markOpened(widget.capsule.id);
    if (mounted) Haptics.tap(ref.read(hapticsEnabledProvider));
  }

  Future<void> _saveReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Напиши пару слов сначала')));
      return;
    }
    await ref
        .read(letterActionsProvider.notifier)
        .setReply(widget.capsule.id, text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    Haptics.tap(ref.read(hapticsEnabledProvider));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ответ сохранён')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch the live row so replies render immediately after saving.
    final capsule =
        ref.watch(letterProvider(widget.capsule.id)).value ?? widget.capsule;
    final created = dateFromUnix(capsule.createdAt);
    final accent = AppColors.warmAmber;

    return Scaffold(
      key: K.letterScreen,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            key: K.letterClose,
            tooltip: 'Закрыть',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.markunread_mailbox_rounded,
                    size: 32,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Это написал ты ${wroteAgoLabel(capsule)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${formatFullDate(created)} · одна фраза о дне',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 32),
              Material(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.borderL,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    capsule.body.trim(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _ReplyComposer(
                controller: _replyController,
                initial: capsule.reply,
                onSave: _saveReply,
              ),
              const SizedBox(height: 28),
              PressableScale(
                child: FilledButton.icon(
                  key: K.letterNewCapsule,
                  onPressed: () =>
                      context.pushReplacement('/capsules', extra: true),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Создать новую капсулу'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short written reply to the opened letter. Free-form — not a goal, not a
/// score, just words back to yourself.
class _ReplyComposer extends StatefulWidget {
  const _ReplyComposer({
    required this.controller,
    required this.initial,
    required this.onSave,
  });

  final TextEditingController controller;
  final String? initial;
  final VoidCallback onSave;

  @override
  State<_ReplyComposer> createState() => _ReplyComposerState();
}

class _ReplyComposerState extends State<_ReplyComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.text = widget.initial ?? '';
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
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.borderL,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ответ',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Пара слов себе сейчас — не цель и не задача, просто отклик.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: K.letterReplyField,
              controller: widget.controller,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Что ответишь этому себе?',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                counterText: '',
                filled: true,
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                key: K.letterReplySave,
                onPressed: widget.onSave,
                icon: const Icon(Icons.reply_rounded, size: 18),
                label: const Text('Сохранить ответ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
