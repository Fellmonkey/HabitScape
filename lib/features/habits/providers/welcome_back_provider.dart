import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/exposure.dart';
import '../../../domain/models/entities.dart';
import '../../capsule/providers/letter_providers.dart';
import '../../stats/providers/year_summary_providers.dart';
import 'habit_streams.dart';

/// Eligibility plus the "what you built" facts for the return-welcome dialog.
class WelcomeBackData {
  const WelcomeBackData({
    required this.eligible,
    required this.habitCount,
    required this.hasMoments,
    required this.hasYear,
    required this.dueCapsule,
  });

  final bool eligible;
  final int habitCount;
  final bool hasMoments;
  final bool hasYear;
  final Letter? dueCapsule;
}

/// Owns the visit bookkeeping and fact gathering. The widget only renders the
/// dialog when [eligible] is true; it no longer reads providers or writes
/// exposure state itself.
final welcomeBackProvider =
    NotifierProvider<WelcomeBackNotifier, WelcomeBackData?>(WelcomeBackNotifier.new);

class WelcomeBackNotifier extends Notifier<WelcomeBackData?> {
  @override
  WelcomeBackData? build() => null;

  Future<WelcomeBackData> check() async {
    final exposure = await ref.read(exposureProvider.future);
    // Eligibility is read BEFORE the visit: recording it resets the absence.
    final eligible = exposure.shouldShowWelcomeBack;
    await ref.read(exposureActionsProvider.notifier).recordVisit();

    if (!eligible) {
      return state = const WelcomeBackData(
        eligible: false,
        habitCount: 0,
        hasMoments: false,
        hasYear: false,
        dueCapsule: null,
      );
    }
    await ref.read(exposureActionsProvider.notifier).markWelcomeShown();

    final data = WelcomeBackData(
      eligible: true,
      habitCount: ref.read(activeHabitsProvider).value?.length ?? 0,
      hasMoments: ref.read(hasAnyDayNoteProvider).value ?? false,
      hasYear: ref.read(yearSummaryProvider).value?.hasData ?? false,
      dueCapsule: ref.read(capsuleFeedProvider).value?.due.firstOrNull,
    );
    return state = data;
  }
}
