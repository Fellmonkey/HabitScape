import '../../../core/database/app_database.dart';
import '../../../core/database/enums.dart';

/// The editable state of one day note.
///
/// Owns the text, mood, and the legacy time-quality value, plus the one rule
/// both editors share: an empty draft clears the stored row instead of
/// writing an empty one.
class DayMomentDraft {
  const DayMomentDraft({
    this.moment = '',
    this.mood,
    this.timeQuality,
    this.isPersisted = false,
  });

  factory DayMomentDraft.fromNote(DayNote? note) {
    return DayMomentDraft(
      moment: note?.moment ?? '',
      mood: note?.mood,
      timeQuality: note?.timeQuality,
      isPersisted: note != null,
    );
  }

  final String moment;
  final DayMood? mood;

  /// Legacy 1–5 "time quality" value. No longer asked, but preserved on edit
  /// so old notes don't silently lose data.
  final int? timeQuality;

  /// Whether a row already exists for this day. An emptied persisted draft
  /// still needs a save so the row can be cleared.
  final bool isPersisted;

  String get trimmedMoment => moment.trim();

  bool get hasMoment => trimmedMoment.isNotEmpty;

  bool get isEmpty => !hasMoment && mood == null && timeQuality == null;

  bool get canSave => !isEmpty || isPersisted;

  String? get momentOrNull => hasMoment ? trimmedMoment : null;

  DayMomentDraft withMoment(String moment) {
    return DayMomentDraft(
      moment: moment,
      mood: mood,
      timeQuality: timeQuality,
      isPersisted: isPersisted,
    );
  }

  /// Tapping the selected mood clears it; both editors share this rule.
  DayMomentDraft toggleMood(DayMood mood) {
    return DayMomentDraft(
      moment: moment,
      mood: this.mood == mood ? null : mood,
      timeQuality: timeQuality,
      isPersisted: isPersisted,
    );
  }

  DayMomentDraft markPersisted() {
    return DayMomentDraft(
      moment: moment,
      mood: mood,
      timeQuality: timeQuality,
      isPersisted: true,
    );
  }
}
