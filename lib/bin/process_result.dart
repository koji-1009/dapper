/// Processing result for files and directories.
library;

/// Processing result for files and directories.
enum ProcessResult {
  /// No formatting changes were needed.
  unchanged,

  /// One or more files were reformatted.
  changed,

  /// An error occurred during processing.
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
