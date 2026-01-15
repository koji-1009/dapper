/// Processing result for files and directories.
enum ProcessResult {
  unchanged,
  changed,
  error;

  /// Merges this result with another, preserving the most severe state.
  ///
  /// Priority: error > changed > unchanged
  ProcessResult merge(ProcessResult other) {
    if (this == error || other == error) return error;
    if (this == changed || other == changed) return changed;
    return unchanged;
  }
}
