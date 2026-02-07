/// CLI utilities for Dapper formatter.
///
/// **WARNING**: This library depends on `dart:io` and cannot be used in
/// web/browser environments. For web-compatible code, use `package:dapper/dapper.dart`.
///
/// This library provides:
/// - [DapperCli]: Command-line interface for formatting files
/// - [ConfigLoader]: Load options from configuration files
/// - [IgnoreRules]: Gitignore-style file filtering
///
/// Example:
/// ```dart
/// import 'package:dapper/bin.dart';
///
/// void main(List<String> args) {
///   run(args);
/// }
/// ```
library;

export 'bin/config_loader.dart';
export 'bin/dapper_cli.dart';
export 'bin/exit_code.dart';
export 'bin/file_system.dart';
export 'bin/ignore_rules.dart';
export 'bin/output_mode.dart';
export 'bin/process_result.dart';
