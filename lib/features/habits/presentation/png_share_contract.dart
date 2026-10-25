/// Outcome of a PNG share attempt.
///
/// The share seam returns this instead of throwing, so every platform adapter
/// reports the same vocabulary — [shared] delivered the file, [cancelled]
/// is a user/fallback decision that needs no error UI, [failed] is a real
/// failure the caller should surface.
enum ShareOutcome { shared, cancelled, failed }
