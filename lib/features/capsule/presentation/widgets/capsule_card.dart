import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../domain/capsule.dart';
import '../../providers/letter_providers.dart';

/// «Капсула»: a card on the greenhouse that surfaces time capsules.
///
/// Priority: a due letter (opens fullscreen) → a locked one (shows the
/// opening date) → an invitation once the user has been around for 30 days.
/// Hidden entirely on a fresh install.
class CapsuleCard extends ConsumerWidget {
  const CapsuleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(capsuleFeedProvider).value;
    if (feed == null) return const SizedBox.shrink();

    final hasOldNote = ref.watch(hasOldNoteProvider).value ?? false;

    final Widget child;
    if (feed.due.isNotEmpty) {
      child = _DueCard(capsule: feed.due.first);
    } else if (feed.upcoming.isNotEmpty) {
      child = _UpcomingCard(capsules: feed.upcoming, today: feed.today);
    } else if (hasOldNote) {
      child = _InviteCard();
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: child,
    );
  }
}

/// A letter that arrived: tap to open the fullscreen letter.
class _DueCard extends StatelessWidget {
  const _DueCard({required this.capsule});

  final Letter capsule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.warmAmber;

    return Material(
      key: K.capsuleCardDue,
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.borderL,
      child: InkWell(
        borderRadius: AppRadius.borderL,
        onTap: () => context.push('/letter', extra: capsule),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.markunread_mailbox_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Письмо из прошлого',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Это написал ты ${wroteAgoLabel(capsule)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A locked capsule: shows the opening date and remaining days.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.capsules, required this.today});

  final List<Letter> capsules;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = capsules.first;
    final left = daysUntil(first, today);
    final extra = capsules.length - 1;
    final opensAt = formatShortDate(
      dateFromUnix(first.deliverAt),
      today: today,
    );

    return Material(
      key: K.capsuleCard,
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.borderL,
      child: InkWell(
        borderRadius: AppRadius.borderL,
        onTap: () => context.push('/capsules'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.softLavender.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.softLavender,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Капсула времени',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Откроется $opensAt · осталось $left ${pluralDays(left)}'
                      '${extra > 0 ? ' · и ещё $extra' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Invitation shown once the archive is at least 30 days old.
class _InviteCard extends StatelessWidget {
  const _InviteCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.sageGreen;

    return Material(
      key: K.capsuleCardInvite,
      color: theme.colorScheme.surface,
      borderRadius: AppRadius.borderL,
      child: InkWell(
        borderRadius: AppRadius.borderL,
        onTap: () => context.push('/capsules'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.markunread_mailbox_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Напиши письмо себе',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Одна фраза — и через месяц ты её прочитаешь',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
