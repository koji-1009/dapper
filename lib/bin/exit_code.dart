/// CLI exit codes.
library;

/// CLI exit codes.
///
/// Error codes follow the POSIX conventions in `sysexits.h`.
enum ExitCode {
  /// Successful execution.
  success(0),

  /// Files were changed (used with `--set-exit-if-changed`).
  changed(1),

  /// Invalid command-line usage (`EX_USAGE`).
  usage(64),

  /// A file or directory could not be processed (`EX_DATAERR`).
  error(65),

  /// An unexpected internal error occurred (`EX_SOFTWARE`).
  software(70);

  const ExitCode(this.code);

  /// The numeric exit code.
  final int code;
}
