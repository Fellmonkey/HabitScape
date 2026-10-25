import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/completion.dart';
import '../../../../core/settings/today.dart';
import 'month_spread_sections.dart';

/// The month spread composition: summary, calendar, goals, and moments.
///
/// Renders the live screen (a scroll view with keys and hint targets) by
/// default; with [capture] set, it renders the same sections in the PNG
/// export chrome (no interaction, no onboarding targets, no test keys, no
/// goals card). One widget, one place to test both renderings.
class MonthSpreadView extends ConsumerWidget {
  const MonthSpreadView({
    required this.days,
    required this.monthTs,
    required this.summary,
    required this.onDayTap,
    this.capture = false,
    super.key,
  });

  final List<MonthSpreadDay> days;
  final int monthTs;
  final MonthSpreadSummary summary;
  final ValueChanged<DateTime> onDayTap;

  /// Whether this is the PNG-export rendering (see class docs).
  final bool capture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayDateProvider);
    final sections = buildSpreadSections(
      context,
      today,
      capture ? MonthSpreadStyle.capture : MonthSpreadStyle.live,
      days: days,
      monthTs: monthTs,
      onDayTap: onDayTap,
      summary: summary,
    );

    if (capture) {
      final theme = Theme.of(context);
      return Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            for (final section in sections) section,
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        for (final section in sections) SliverToBoxAdapter(child: section),
      ],
    );
  }
}
