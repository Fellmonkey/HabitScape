import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/formatting/formatting.dart';
import '../../../../core/keys.dart';
import '../../../../core/settings/today.dart';
import '../../../../core/domain/completion.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/motion_tokens.dart';
import '../../providers/stats_providers.dart';
import '../../providers/year_summary_providers.dart';
import '../widgets/archive_card.dart';
import '../widgets/heatmap_card.dart';
import '../widgets/intentions_card.dart';
import '../widgets/mood_correlation_card.dart';
import '../widgets/month_trend_card.dart';
import '../widgets/rhythm_card.dart';
import '../widgets/week_trend_card.dart';

/// Statistics screen — an informative dashboard across everything.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsOverviewProvider);
    final today = ref.watch(todayDateProvider);
    void showDayDetail(DayCompletion day) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderL),
          title: Text(formatFullDate(day.date)),
          content: Text('Выполнено: ${day.done} из ${day.expected}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    // The year button only appears once there is actually something to show
    // on the year screen — the empty state would only invite confusion.
    final hasHistory = ref.watch(yearSummaryProvider).value?.hasData ?? false;
    final scrollView = CustomScrollView(
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статистика',
                        key: K.statsTitle,
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatFullDate(today),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (hasHistory)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: OutlinedButton.icon(
                      key: K.yearSummaryOpen,
                      onPressed: () => context.push('/year'),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Итоги года'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        ...statsAsync.when(
          loading: () => const [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (_, _) => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Не удалось загрузить статистику',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Попробуй чуть позже',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          data: (stats) => [
            // Before there is anything to summarize, one invitation card
            // replaces the whole dashboard — no forest of empty headers.
            if (stats.activeDays < AppConstants.statsInviteDays)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: _StatsInviteCard(),
                ),
              )
            else ...[
              // ── Week trend ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: WeekTrendCard(stats: stats),
                ),
              ),

              // ── Year heatmap ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: HeatmapCard(
                    stats: stats,
                    today: today,
                    onDayTap: showDayDetail,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Month trend ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: MonthlyTrendCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Advanced insights unlock only after enough observation days —
              // correlation and rhythm need a real sample to be meaningful.
              if (stats.activeDays >=
                  AppConstants.statsAdvancedInsightsDays) ...[
                // ── Mood ↔ completion ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: MoodCorrelationCard(corr: stats.moodCorrelation),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Weekly rhythm ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RhythmCard(rhythm: stats.rhythm),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // ── Intentions ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: IntentionsCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ── Archive (bottom) ──
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ArchiveCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ],
    );

    // Gentle entrance once the first data frame arrives — opacity + a small
    // rise, strong ease-out. Reduced-motion users get the plain scroll view.
    if (AppMotion.mayDisable(context)) {
      return Scaffold(body: SafeArea(child: scrollView));
    }
    return Scaffold(
      body: SafeArea(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: statsAsync.hasValue ? 1 : 0, end: 1),
          duration: AppMotion.slow,
          curve: AppMotion.easeOutStrong,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          ),
          child: scrollView,
        ),
      ),
    );
  }
}

/// The single card shown before the dashboard has anything to summarize.
/// Invites the two rituals the stats are built from: habits and moments.
class _StatsInviteCard extends StatelessWidget {
  const _StatsInviteCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.borderL,
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 44,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 14),
          Text(
            'Здесь появятся тренды',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Отмечай привычки и записывай моменты — '
            'накопится немного данных, и статистика оживёт.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
