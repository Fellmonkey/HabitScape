import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/moment.dart' as moment_kernel;
import '../../../../core/theme/motion_tokens.dart';
import '../../providers/day_note_providers.dart';
import 'day_moment_composer.dart';
import 'day_moment_saved.dart';

/// Greenhouse card for today's day moment.
///
/// Empty state is an inline composer: one line + three mood buttons + save.
/// The whole ritual stays on the card — no sheet, no extra decisions.
/// A saved note opens the sheet for deeper editing.
class DayMomentCard extends ConsumerWidget {
  const DayMomentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(todayDayNoteProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: noteAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (note) {
          final hasMoment = moment_kernel.hasMoment(note?.moment);
          if (AppMotion.mayDisable(context)) {
            return hasMoment
                ? DayMomentSaved(note: note!)
                : DayMomentComposer(initial: note);
          }
          return AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.easeOutStrong,
            switchOutCurve: AppMotion.easeOutStrong,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.97, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: hasMoment
                ? DayMomentSaved(key: const ValueKey('saved'), note: note!)
                : DayMomentComposer(
                    key: const ValueKey('composer'),
                    initial: note,
                  ),
          );
        },
      ),
    );
  }
}
