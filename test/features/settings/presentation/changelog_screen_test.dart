import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rythm/core/config/app_constants.dart';
import 'package:rythm/core/theme/app_theme.dart';
import 'package:rythm/features/settings/domain/changelog.dart';
import 'package:rythm/features/settings/presentation/screens/changelog_screen.dart';
import 'package:rythm/features/settings/providers/changelog_providers.dart';

void main() {
  testWidgets('renders releases and marks the current version', (tester) async {
    final changelog = Changelog(
      releases: [
        ChangelogRelease(
          version: AppConstants.appVersion,
          date: DateTime.utc(2026, 10, 29),
          sections: const [
            ChangelogSection(title: 'Добавлено', items: ['Первая функция']),
          ],
        ),
        ChangelogRelease(
          version: '0.9.0',
          date: DateTime.utc(2026, 9, 1),
          sections: const [
            ChangelogSection(title: 'Исправлено', items: ['Старый баг']),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [changelogProvider.overrideWith((ref) async => changelog)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChangelogScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Что нового'), findsOneWidget);
    expect(find.text('Версия ${AppConstants.appVersion}'), findsOneWidget);
    expect(find.text('Текущая версия'), findsOneWidget);
    expect(find.text('Добавлено'), findsOneWidget);
    expect(find.text('Первая функция'), findsOneWidget);
    expect(find.text('Версия 0.9.0'), findsOneWidget);
    expect(find.text('Исправлено'), findsOneWidget);
    expect(find.text('Старый баг'), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no releases', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          changelogProvider.overrideWith(
            (ref) async => const Changelog(releases: []),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChangelogScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('История изменений пока пуста.'), findsOneWidget);
  });

  testWidgets('offers a retry when the changelog cannot be loaded', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          changelogProvider.overrideWith(
            (ref) async => throw StateError('broken asset'),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChangelogScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить историю изменений'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}
