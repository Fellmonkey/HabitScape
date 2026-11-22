import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/entities.dart';
import '../../providers/welcome_back_provider.dart';

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

    final data = await ref.read(welcomeBackProvider.notifier).check();
    if (!mounted || !data.eligible) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _WelcomeBackDialog(
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

/// The dialog itself. Facts are watched live so a first-frame `0/false`
/// placeholder is replaced as soon as the underlying streams produce values.
class _WelcomeBackDialog extends ConsumerWidget {
  const _WelcomeBackDialog({
    required this.onStartDay,
    required this.onOpenYear,
    required this.onOpenLetter,
  });

  final VoidCallback onStartDay;
  final VoidCallback onOpenYear;
  final ValueChanged<Letter> onOpenLetter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = ref.watch(welcomeBackFactsProvider);
    final habitCount = facts.habitCount;
    final hasMoments = facts.hasMoments;
    final hasYear = facts.hasYear;
    final dueCapsule = facts.dueCapsule;
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
                onPressed: () => onOpenLetter(dueCapsule),
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
