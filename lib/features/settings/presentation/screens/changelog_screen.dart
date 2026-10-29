import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/today.dart';
import '../../providers/changelog_providers.dart';
import '../widgets/changelog_release_card.dart';

/// «Что нового»: the in-app rendering of the repo-root CHANGELOG.md.
class ChangelogScreen extends ConsumerWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changelogAsync = ref.watch(changelogProvider);
    final today = ref.watch(todayDateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: K.changelogScreen,
      appBar: AppBar(title: const Text('Что нового')),
      body: changelogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _ErrorState(onRetry: () => ref.invalidate(changelogProvider)),
        data: (changelog) {
          if (changelog.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'История изменений пока пуста.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: changelog.releases.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return const _ChangelogIntro();
              final release = changelog.releases[index - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChangelogReleaseCard(
                  key: K.changelogRelease(release.version),
                  release: release,
                  isCurrent: release.version == AppConstants.appVersion,
                  today: today,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChangelogIntro extends StatelessWidget {
  const _ChangelogIntro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        'Всё, что менялось в HabitScape — от новых функций до исправлений.',
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить историю изменений',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Попробуй открыть экран ещё раз.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
