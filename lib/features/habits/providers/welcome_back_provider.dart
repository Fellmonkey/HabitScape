import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/history_store_provider.dart';
import '../../../core/settings/exposure.dart';
import '../../../domain/models/entities.dart';
import '../../capsule/providers/letter_providers.dart';
import '../../stats/providers/year_summary_providers.dart';
import 'habit_streams.dart';

/// Live facts for the dialog. Each source is watched, so the dialog updates
/// as soon as streams/futures produce their first value instead of freezing
/// the `0/false` placeholders from the first frame.
final welcomeBackFactsProvider = Provider<WelcomeBackData>((ref) {
  final habits = ref.watch(activeHabitsProvider).value;
  final hasMoments = ref.watch(hasAnyDayNoteProvider).value;
  final year = ref.watch(yearSummaryProvider).value;
  final capsuleFeed = ref.watch(capsuleFeedProvider).value;
  return WelcomeBackData(
    eligible: true,
    habitCount: habits?.length ?? 0,
    hasMoments: hasMoments ?? false,
    hasYear: year?.hasData ?? false,
    dueCapsule: capsuleFeed?.due.firstOrNull,
  );
});

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
    NotifierProvider<WelcomeBackNotifier, WelcomeBackData?>(
      WelcomeBackNotifier.new,
    );

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

    // Await every fact source. Reading `.value` here silently degraded to
    // 0/false while a provider was still loading, which could show an empty
    // welcome dialog to a user with history.
    // The dialog watches `welcomeBackFactsProvider` for live facts, so these
    // first-frame values are only an immediate fallback, not a silent final
    // answer while the streams are still loading.
    return state = WelcomeBackData(
      eligible: true,
      habitCount: ref.read(activeHabitsProvider).value?.length ?? 0,
      hasMoments: ref.read(hasAnyDayNoteProvider).value ?? false,
      hasYear: ref.read(yearSummaryProvider).value?.hasData ?? false,
      dueCapsule: ref.read(capsuleFeedProvider).value?.due.firstOrNull,
    );
  }
}
