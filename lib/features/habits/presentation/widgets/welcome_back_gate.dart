import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/history_store_provider.dart';
import '../../../../core/settings/exposure.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/capsule/providers/letter_providers.dart';
import '../../../../features/stats/providers/year_summary_providers.dart';
import '../../providers/habit_streams.dart';

/// The return-welcome: shown once per absence episode (7+ days without
/// opening the app). Records every visit and only appears when the episode
/// has not been welcomed yet. Soft, non-judgmental tone — it surfaces what
/// was built rather than what was missed.
class WelcomeBackGate extends ConsumerStatefulWidget {
  const WelcomeBackGate({super.key});

  @override
  ConsumerState<WelcomeBackGate> createState() => _WelcomeBackGateState();
}

class _WelcomeBackGateState extends ConsumerState<WelcomeBackGate> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (_checked) return;
    _checked = true;

    final exposure = await ref.read(exposureProvider.future);
    // Eligibility is read BEFORE the visit — Exposure getters read the store
    // live, and recording the visit would immediately reset the absence.
    final eligible = exposure.shouldShowWelcomeBack;
    // Every open is a visit; the welcome is a one-off per absence episode.
    await ref.read(exposureActionsProvider.notifier).recordVisit();
    if (!mounted || !eligible) return;
    await ref.read(exposureActionsProvider.notifier).markWelcomeShown();
    if (!mounted) return;

    // Gather the "what you built" facts up front.
    final habitCount = ref.read(activeHabitsProvider).value?.length ?? 0;
    final hasMoments = ref.read(hasAnyDayNoteProvider).value ?? false;
    final hasYear = ref.read(yearSummaryProvider).value?.hasData ?? false;
    final dueCapsule = ref.read(capsuleFeedProvider).value?.due.firstOrNull;

    if (!mounted) return;
    await _showWelcome(
      habitCount: habitCount,
      hasMoments: hasMoments,
      hasYear: hasYear,
      dueCapsule: dueCapsule,
    );
  }

  Future<void> _showWelcome({
    required int habitCount,
    required bool hasMoments,
    required bool hasYear,
    required Letter? dueCapsule,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _WelcomeBackDialog(
        habitCount: habitCount,
        hasMoments: hasMoments,
        hasYear: hasYear,
        dueCapsule: dueCapsule,
        onStartDay: () => Navigator.of(context).pop(),
        onOpenYear: () {
          Navigator.of(context).pop();
          context.push('/year');
        },
        onOpenLetter: (capsule) {
          Navigator.of(context).pop();
          context.push('/letter', extra: capsule);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// The dialog itself — pure content, no providers.
class _WelcomeBackDialog extends StatelessWidget {
  const _WelcomeBackDialog({
    required this.habitCount,
    required this.hasMoments,
    required this.hasYear,
    required this.dueCapsule,
    required this.onStartDay,
    required this.onOpenYear,
    required this.onOpenLetter,
  });

  final int habitCount;
  final bool hasMoments;
  final bool hasYear;
  final Letter? dueCapsule;
  final VoidCallback onStartDay;
  final VoidCallback onOpenYear;
  final ValueChanged<Letter> onOpenLetter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.palette.emerald.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  size: 32,
                  color: context.palette.emerald,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'С возвращением!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ничего не сброшено — всё на месте.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            // ── What you built ──
            if (habitCount > 0)
              _FactRow(
                icon: Icons.local_florist_rounded,
                text:
                    'У тебя $habitCount привычек — продолжай, где остановился.',
              ),
            if (hasMoments)
              const _FactRow(
                icon: Icons.edit_note_rounded,
                text: 'Твои моменты сохранены.',
              ),
            if (dueCapsule != null)
              _FactRow(
                icon: Icons.markunread_mailbox_rounded,
                text: 'Тебя ждёт письмо из прошлого.',
              ),
            if (hasYear)
              const _FactRow(
                icon: Icons.auto_awesome_rounded,
                text: 'Год почти прожит — посмотри, что получилось.',
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onStartDay,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderM),
              ),
              child: const Text('Начать день'),
            ),
            if (hasYear) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onOpenYear,
                child: const Text('Итоги года'),
              ),
            ],
            if (dueCapsule != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onOpenLetter(dueCapsule!),
                child: const Text('Открыть письмо'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.palette.sage),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
