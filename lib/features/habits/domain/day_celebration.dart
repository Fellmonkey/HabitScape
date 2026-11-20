/// The «день закрыт» rule: one quiet celebration per calendar day, on the
/// transition from an incomplete to a complete board. Pure so the decision can
/// be tested without a widget or a snackbar.
bool shouldCelebrateDayClose({
  required double previousProgress,
  required double progress,
  required int? celebratedDay,
  required int dayKey,
}) {
  if (previousProgress >= 1.0 || progress < 1.0) return false;
  return celebratedDay != dayKey;
}
