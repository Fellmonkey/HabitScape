import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/completion.dart';
import '../../../../core/settings/today.dart';
import 'month_spread_sections.dart';

/// The live month spread composition: summary, calendar, goals, and moments.
///
/// The PNG exporter renders the same sections through [MonthSpreadCaptureView]
/// (see month_spread_capture_view.dart); both share the primitives in
/// month_spread_sections.dart.
class MonthSpreadView extends ConsumerWidget {
  const MonthSpreadView({
    required this.days,
    required this.monthTs,
    required this.summary,
    required this.onDayTap,
    super.key,
  });

  final List<MonthSpreadDay> days;
  final int monthTs;
  final MonthSpreadSummary summary;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayDateProvider);
    final sections = buildSpreadSections(
      context,
      today,
      MonthSpreadStyle.live,
      days: days,
      monthTs: monthTs,
      onDayTap: onDayTap,
      summary: summary,
    );

    return CustomScrollView(
      slivers: [
        for (final section in sections) SliverToBoxAdapter(child: section),
      ],
    );
  }
}
