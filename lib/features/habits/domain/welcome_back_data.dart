import '../../../domain/models/entities.dart';

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

/// Pure composition shared by the live facts provider and the one-shot check,
/// so both surfaces can never disagree about the dialog's content.
WelcomeBackData buildWelcomeBackData({
  required bool eligible,
  required int habitCount,
  required bool hasMoments,
  required bool hasYear,
  required Letter? dueCapsule,
}) {
  if (!eligible) {
    return const WelcomeBackData(
      eligible: false,
      habitCount: 0,
      hasMoments: false,
      hasYear: false,
      dueCapsule: null,
    );
  }
  return WelcomeBackData(
    eligible: true,
    habitCount: habitCount,
    hasMoments: hasMoments,
    hasYear: hasYear,
    dueCapsule: dueCapsule,
  );
}
