import 'package:flutter/material.dart';

import '../../../../core/keys.dart';

/// Layout differences between the live screen and the PNG exporter.
///
/// Both modes render the same section primitives; the style only picks
/// chrome (keys, hint targets, insets, whether goals appear).
class MonthSpreadStyle {
  const MonthSpreadStyle({
    required this.summaryInsets,
    required this.gridKey,
    required this.debugDayKeys,
    required this.wrapGridInHint,
    required this.includeGoals,
    required this.momentsTitleInsets,
    required this.momentsListInsets,
    required this.momentsKey,
    required this.preMomentsGap,
  });

  final EdgeInsets summaryInsets;
  final Key gridKey;
  final bool debugDayKeys;
  final bool wrapGridInHint;
  final bool includeGoals;
  final EdgeInsets momentsTitleInsets;
  final EdgeInsets momentsListInsets;
  final Key? momentsKey;
  final double preMomentsGap;

  static const live = MonthSpreadStyle(
    summaryInsets: EdgeInsets.fromLTRB(20, 8, 20, 8),
    gridKey: K.monthSpreadGrid,
    debugDayKeys: true,
    wrapGridInHint: true,
    includeGoals: true,
    momentsTitleInsets: EdgeInsets.fromLTRB(20, 8, 20, 4),
    momentsListInsets: EdgeInsets.fromLTRB(20, 0, 20, 24),
    momentsKey: K.monthSpreadMoments,
    preMomentsGap: 0,
  );

  static const capture = MonthSpreadStyle(
    summaryInsets: EdgeInsets.zero,
    gridKey: Key('month_spread_grid_capture'),
    debugDayKeys: false,
    wrapGridInHint: false,
    includeGoals: false,
    momentsTitleInsets: EdgeInsets.zero,
    momentsListInsets: EdgeInsets.zero,
    momentsKey: null,
    preMomentsGap: 8,
  );
}
