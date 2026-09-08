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
/// Opening a letter marks it as read. «Ответить себе» closes it and goes to
/// the composer so the reply becomes a new capsule.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capsule = widget.capsule;
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
              const SizedBox(height: 40),
              FilledButton.icon(
                key: K.letterReply,
                onPressed: () =>
                    context.pushReplacement('/capsules', extra: true),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Ответить себе'),
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
