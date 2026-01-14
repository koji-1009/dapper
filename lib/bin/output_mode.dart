/// Output modes for formatted content.
enum OutputMode {
  write,
  show,
  json,
  none;

  static OutputMode fromString(String value) => switch (value) {
    'write' => OutputMode.write,
    'show' => OutputMode.show,
    'json' => OutputMode.json,
    'none' => OutputMode.none,
    _ => OutputMode.write,
  };
}
