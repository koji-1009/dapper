/// Main entry point for the Dapper formatter.
///
/// This library provides the core formatters and options used by the CLI.
///
/// Usage:
/// ```dart
/// import 'package:dapper/dapper.dart';
///
/// final output = formatMarkdown('# Hello');
/// ```
library;

export 'src/markdown/markdown_formatter.dart'
    show MarkdownFormatter, formatMarkdown;
export 'src/options.dart';
export 'src/yaml/yaml_formatter.dart' show YamlFormatter, formatYaml;
