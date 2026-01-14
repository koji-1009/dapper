/// CLI exit codes.
enum ExitCode {
  success(0),
  error(1),
  changed(1);

  const ExitCode(this.code);
  final int code;
}
