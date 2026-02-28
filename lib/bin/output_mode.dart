/// Output modes for formatted content.
library;

/// Output modes for formatted content.
enum OutputMode {
  /// Overwrite formatted files on disk.
  write,

  /// Print formatted code to stdout.
  show,

  /// Output formatted code as JSON.
  json,

  /// Discard output (useful for checking if files need formatting).
  none;

  /// Parses a string into an [OutputMode], defaulting to [write].
  static OutputMode fromString(String value) => switch (value) {
    'write' => OutputMode.write,
    'show' => OutputMode.show,
    'json' => OutputMode.json,
    'none' => OutputMode.none,
    _ => OutputMode.write,
  };
}
