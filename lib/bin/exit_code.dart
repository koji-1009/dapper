/// CLI exit codes.
library;

/// CLI exit codes.
enum ExitCode {
  /// Successful execution.
  success(0),

  /// An error occurred during execution.
  error(1),

  /// Files were changed (used with `--set-exit-if-changed`).
  changed(1);

  const ExitCode(this.code);

  /// The numeric exit code.
  final int code;
}
