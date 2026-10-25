/// The one rule for "is there a memorable moment written" — non-empty after
/// trimming. Every reader of a day note's moment (the day-moment module, the
/// echo feed, the completion kernel, the spread grid) imports this predicate,
/// so a whitespace/emoji-policy change lands in exactly one place.
bool hasMoment(String? moment) => moment != null && moment.trim().isNotEmpty;
