/// The one normalizing rule for weekly intentions: trim and treat blank text
/// as "no intention". Pure so repositories, DAOs and tests share one policy.
String? normalizeIntention(String? raw) {
  final trimmed = raw?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
