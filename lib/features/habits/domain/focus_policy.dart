/// The one owner of the focus-habit cap rule.
///
/// `mayEnableFocus` is pure — command layers run it inside their own write
/// transaction, so atomicity stays at the command, not in storage.
class FocusPolicy {
  const FocusPolicy._();

  /// Whether enabling focus on one more habit stays within [cap].
  static bool mayEnableFocus(int currentFocusCount, {required int cap}) {
    return currentFocusCount < cap;
  }
}
