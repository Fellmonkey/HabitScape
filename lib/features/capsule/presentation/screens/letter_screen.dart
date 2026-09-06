import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/localized_dates.dart';
import '../../domain/capsule.dart';
import '../../providers/letter_providers.dart';

/// Fullscreen letter: what you wrote to yourself, shown on the day it opened.
///
/// Opening a letter marks it as read and lets you leave a written verdict
/// (Получилось / Частично / Нет). «Создать новую капсулу» closes the letter
/// and opens a fresh composer — a new message, not a quoted reply.
class LetterScreen extends ConsumerStatefulWidget {
  const LetterScreen({super.key, required this.capsule});

  final Letter capsule;

  @override
  ConsumerState<LetterScreen> createState() => _LetterScreenState();
}

class _LetterScreenState extends ConsumerState<LetterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markOpened());
  }

  Future<void> _markOpened() async {
    if (widget.capsule.isOpened) return;
    await ref
        .read(letterActionsProvider.notifier)
        .markOpened(widget.capsule.id);
  }

  Future<void> _setReaction(CapsuleReaction reaction) async {
    await ref
        .read(letterActionsProvider.notifier)
        .setReaction(widget.capsule.id, reaction);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch the live row so verdicts and open state render immediately.
    final capsule =
        ref.watch(letterProvider(widget.capsule.id)).value ?? widget.capsule;
    final created = dateFromUnix(capsule.createdAt);
    final accent = AppColors.warmAmber;
    final reaction = CapsuleReaction.fromString(capsule.reaction);

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
              if (reaction == null)
                _ReactionPicker(onSelected: _setReaction)
              else
                _ReactionResult(reaction: reaction),
              const SizedBox(height: 28),
              FilledButton.icon(
                key: K.letterNewCapsule,
                onPressed: () =>
                    context.pushReplacement('/capsules', extra: true),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Создать новую капсулу'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: K.letterCloseText,
                onPressed: () => context.pop(),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three quick verdicts: success / partial / missed — written confirmation of
/// what came of the message.
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({required this.onSelected});

  final ValueChanged<CapsuleReaction> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Как получилось?',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reaction in CapsuleReaction.values)
              ActionChip(
                key: K.letterReaction(reaction.name),
                label: Text(reaction.label),
                onPressed: () => onSelected(reaction),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReactionResult extends StatelessWidget {
  const _ReactionResult({required this.reaction});

  final CapsuleReaction reaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 18, color: reaction.color),
        const SizedBox(width: 6),
        Text(
          'Ты отметил: ${reaction.label}',
          style: theme.textTheme.bodyMedium?.copyWith(color: reaction.color),
        ),
      ],
    );
  }
}
