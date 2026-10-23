import '../../../core/config/app_constants.dart';

/// The Today board's focus rule: at most [AppConstants.maxFocusHabits]
/// habits may carry the focus flag. Enabling focus beyond the cap is
/// rejected; disabling is always allowed.
class FocusPolicy {
  const FocusPolicy._();

  /// Whether setting [isFocus] on a habit is allowed, given that
  /// [currentFocusCount] habits are focused right now.
  static bool canSetFocus({
    required int currentFocusCount,
    required bool isFocus,
  }) {
    return !isFocus || currentFocusCount < AppConstants.maxFocusHabits;
  }
}
