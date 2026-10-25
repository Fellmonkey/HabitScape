import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/completion.dart';
import '../../../../core/settings/today.dart';
import 'month_spread_sections.dart';

/// The PNG-export rendering of the month spread: the same sections with no
/// interaction, onboarding targets, test keys, or the goals card.
class MonthSpreadCaptureView extends ConsumerWidget {
  const MonthSpreadCaptureView({
    required this.days,
    required this.monthTs,
    required this.summary,
    super.key,
  });

  final List<MonthSpreadDay> days;
  final int monthTs;
  final MonthSpreadSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayDateProvider);
    final sections = buildSpreadSections(
      context,
      today,
      MonthSpreadStyle.capture,
      days: days,
      monthTs: monthTs,
      onDayTap: (_) {},
      summary: summary,
    );

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
}
