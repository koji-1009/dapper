// Dapper CLI - Format Markdown and YAML files.
//
// Usage: dapper [options] <files or directories...>

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dapper/dapper.dart';
import 'package:glob/glob.dart';
import 'package:yaml/yaml.dart';

void main(List<String> arguments) {
  final result = const DapperCli().run(arguments);
  exit(result.code);
}

/// CLI exit codes.
enum ExitCode {
  success(0),
  error(1),
  changed(1);

  const ExitCode(this.code);
  final int code;
}

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

/// A single gitignore-style pattern with metadata.
///
/// Handles:
/// - Directory patterns (trailing `/`)
/// - Path-based patterns (containing `/`)
/// - Simple name patterns
class IgnorePattern {
  /// The glob pattern for matching.
  final Glob _glob;

  /// Whether this pattern contains a path separator (requires path matching).
  final bool hasPathSeparator;

  /// Whether this pattern is for directories only (originally ended with `/`).
  final bool isDirectoryOnly;

  IgnorePattern._(this._glob, this.hasPathSeparator, this.isDirectoryOnly);

  /// Parses a gitignore-style pattern.
  ///
  /// Returns `null` if the pattern is empty after normalization.
  static IgnorePattern? parse(String pattern) {
    var normalized = pattern;

    // Check if this is a directory-only pattern
    final isDirectoryOnly = normalized.endsWith('/');
    if (isDirectoryOnly) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    // Remove leading slash (anchors to root)
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    if (normalized.isEmpty) {
      return null;
    }

    // Check if pattern has path separator (requires path-based matching)
    final hasPathSeparator = normalized.contains('/');

    return IgnorePattern._(Glob(normalized), hasPathSeparator, isDirectoryOnly);
  }

  /// Checks if this pattern matches the given path.
  ///
  /// [relativePath] is the path relative to the gitignore location.
  /// [isDirectory] indicates if the path is a directory.
  bool matches(String relativePath, {required bool isDirectory}) {
    // Directory-only patterns should not match files
    if (isDirectoryOnly && !isDirectory) {
      return false;
    }

    if (hasPathSeparator) {
      // Pattern has path separator - match against full relative path
      return _glob.matches(relativePath);
    } else {
      // Pattern has no path separator - match against basename only
      return _glob.matches(_basename(relativePath));
    }
  }
}

/// Rules for ignoring files and directories.
///
/// Supports glob patterns and negation patterns (prefixed with `!`).
class IgnoreRules {
  final List<IgnorePattern> _patterns;
  final Set<String> _negations;

  IgnoreRules._(this._patterns, this._negations);

  /// Creates empty rules.
  factory IgnoreRules.empty() => IgnoreRules._([], {});

  /// Parses ignore rules from file content.
  factory IgnoreRules.parse(String content) {
    final patterns = <IgnorePattern>[];
    final negations = <String>{};

    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      if (trimmed.startsWith('!')) {
        negations.add(trimmed.substring(1));
      } else {
        final pattern = IgnorePattern.parse(trimmed);
        if (pattern != null) {
          patterns.add(pattern);
        }
      }
    }

    return IgnoreRules._(patterns, negations);
  }

  /// Loads rules from a file, returns `null` if file doesn't exist.
  static IgnoreRules? loadFromFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }
    return IgnoreRules.parse(file.readAsStringSync());
  }

  /// Loads combined rules from `.gitignore` and `.dapperignore` in a directory.
  static IgnoreRules loadFromDirectory(String directoryPath) {
    var rules = IgnoreRules.empty();

    // Load .gitignore first (lower priority)
    final gitignore = loadFromFile('$directoryPath/.gitignore');
    if (gitignore != null) {
      rules = rules.merge(gitignore);
    }

    // Load .dapperignore second (higher priority)
    final dapperignore = loadFromFile('$directoryPath/.dapperignore');
    if (dapperignore != null) {
      rules = rules.merge(dapperignore);
    }

    return rules;
  }

  /// Whether this rules set is empty.
  bool get isEmpty => _patterns.isEmpty && _negations.isEmpty;

  /// Checks if an entry should be ignored.
  ///
  /// [name] is the basename of the entry.
  /// [defaultIgnored] is a set of names that are always ignored.
  /// [isDirectory] indicates if the entry is a directory.
  bool shouldIgnore(
    String name,
    Set<String> defaultIgnored, {
    bool isDirectory = false,
  }) {
    // Negation patterns can override defaults
    if (_negations.contains(name)) {
      return false;
    }

    // Check default ignored list
    if (defaultIgnored.contains(name)) {
      return true;
    }

    // Check glob patterns
    for (final pattern in _patterns) {
      if (pattern.matches(name, isDirectory: isDirectory)) {
        return true;
      }
    }

    return false;
  }

  /// Merges this rules with another, creating combined rules.
  IgnoreRules merge(IgnoreRules other) {
    return IgnoreRules._(
      [..._patterns, ...other._patterns],
      {..._negations, ...other._negations},
    );
  }
}

/// Loads format options from configuration files.
class ConfigLoader {
  const ConfigLoader();

  /// Loads options from `dapper.yaml` or `analysis_options.yaml`.
  ///
  /// Returns `null` if no configuration is found.
  FormatOptions? loadFromDirectory(String directoryPath) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      return null;
    }

    // Try dapper.yaml first
    final dapperConfig = File('${dir.path}/dapper.yaml');
    if (dapperConfig.existsSync()) {
      return _parseConfigFile(dapperConfig.readAsStringSync());
    }

    // Fall back to analysis_options.yaml
    final analysisOptions = File('${dir.path}/analysis_options.yaml');
    if (analysisOptions.existsSync()) {
      return _parseAnalysisOptions(analysisOptions.readAsStringSync());
    }

    return null;
  }

  FormatOptions? _parseConfigFile(String content) {
    try {
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) {
        return null;
      }
      return _parseOptionsMap(yaml);
    } catch (_) {
      return null;
    }
  }

  FormatOptions? _parseAnalysisOptions(String content) {
    try {
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) {
        return null;
      }
      final dapperBlock = yaml['dapper'];
      if (dapperBlock is! YamlMap) {
        return null;
      }
      return _parseOptionsMap(dapperBlock);
    } catch (_) {
      return null;
    }
  }

  FormatOptions? _parseOptionsMap(YamlMap map) {
    final printWidth =
        _parseInt(map['print_width']) ?? _parseInt(map['printWidth']);
    final tabWidth = _parseInt(map['tab_width']) ?? _parseInt(map['tabWidth']);
    final proseWrap =
        _parseProseWrap(map['prose_wrap']) ?? _parseProseWrap(map['proseWrap']);
    final ulStyle =
        _parseUlStyle(map['ul_style']) ?? _parseUlStyle(map['ulStyle']);

    if (printWidth == null &&
        tabWidth == null &&
        proseWrap == null &&
        ulStyle == null) {
      return null;
    }

    return FormatOptions(
      printWidth: printWidth ?? 80,
      tabWidth: tabWidth ?? 2,
      proseWrap: proseWrap ?? ProseWrap.preserve,
      ulStyle: ulStyle ?? UnorderedListStyle.asterisk,
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  ProseWrap? _parseProseWrap(dynamic value) {
    if (value is! String) return null;
    return switch (value.toLowerCase()) {
      'always' => ProseWrap.always,
      'never' => ProseWrap.never,
      'preserve' => ProseWrap.preserve,
      _ => null,
    };
  }

  UnorderedListStyle? _parseUlStyle(dynamic value) {
    if (value is! String) return null;
    return switch (value.toLowerCase()) {
      'dash' || '-' => UnorderedListStyle.dash,
      'asterisk' || '*' => UnorderedListStyle.asterisk,
      'plus' || '+' => UnorderedListStyle.plus,
      _ => null,
    };
  }
}

/// Command-line interface for the Dapper formatter.
class DapperCli {
  /// Creates a new CLI instance.
  const DapperCli({this.configLoader = const ConfigLoader()});

  final ConfigLoader configLoader;

  static const _noFilesError = 'Error: No files or directories specified.';

  /// Directories to ignore during recursive scanning.
  static const _ignoredDirectories = {
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    '.fvm',
  };

  /// Runs the CLI with the given arguments.
  ///
  /// Returns the exit code.
  ExitCode run(List<String> arguments) {
    // Fast path: no arguments means no files specified
    if (arguments.isEmpty) {
      stderr.writeln(_noFilesError);
      _printUsage('');
      return ExitCode.error;
    }

    final parser = _buildArgParser();

    try {
      final results = parser.parse(arguments);

      if (results['help'] as bool) {
        _printUsage(parser.usage);
        return ExitCode.success;
      }

      final paths = results.rest;
      if (paths.isEmpty) {
        stderr.writeln(_noFilesError);
        _printUsage(parser.usage);
        return ExitCode.error;
      }

      final outputMode = OutputMode.fromString(results['output'] as String);
      final setExitIfChanged = results['set-exit-if-changed'] as bool;
      final options = _resolveOptions(results);

      final result = _processPaths(paths, outputMode, options);

      if (result == ProcessResult.error) {
        return ExitCode.error;
      }
      if (setExitIfChanged && result == ProcessResult.changed) {
        return ExitCode.changed;
      }
      return ExitCode.success;
    } on FormatException catch (e) {
      stderr.writeln('Error: ${e.message}');
      _printUsage(parser.usage);
      return ExitCode.error;
    }
  }

  ArgParser _buildArgParser() {
    return ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print this usage information.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        defaultsTo: 'write',
        allowed: ['write', 'show', 'json', 'none'],
        help: 'Set where to write formatted output.',
        valueHelp: 'mode',
        allowedHelp: {
          'write': 'Overwrite formatted files on disk.',
          'show': 'Print code to terminal.',
          'json': 'Print code as JSON.',
          'none': 'Discard output.',
        },
      )
      ..addFlag(
        'set-exit-if-changed',
        negatable: false,
        help: 'Return exit code 1 if there are any formatting changes.',
      )
      ..addOption(
        'print-width',
        defaultsTo: '80',
        help: 'Maximum line width.',
        valueHelp: 'int',
      )
      ..addOption(
        'prose-wrap',
        defaultsTo: 'preserve',
        allowed: ['always', 'never', 'preserve'],
        help: 'How to wrap prose.',
        valueHelp: 'mode',
      );
  }

  void _printUsage(String usage) {
    stdout.writeln('Idiomatically format Markdown and YAML files.');
    stdout.writeln();
    stdout.writeln('Usage: dapper [options] <files or directories...>');
    if (usage.isNotEmpty) {
      stdout.writeln();
      stdout.writeln(usage);
    }
  }

  FormatOptions _resolveOptions(ArgResults results) {
    final configOptions = configLoader.loadFromDirectory(
      Directory.current.path,
    );

    final cliPrintWidth = results.wasParsed('print-width')
        ? int.tryParse(results['print-width'] as String)
        : null;
    final cliProseWrap = results.wasParsed('prose-wrap')
        ? _parseProseWrap(results['prose-wrap'] as String)
        : null;

    return FormatOptions(
      printWidth: cliPrintWidth ?? configOptions?.printWidth ?? 80,
      tabWidth: configOptions?.tabWidth ?? 2,
      proseWrap: cliProseWrap ?? configOptions?.proseWrap ?? ProseWrap.preserve,
      ulStyle: configOptions?.ulStyle ?? UnorderedListStyle.asterisk,
    );
  }

  ProseWrap _parseProseWrap(String value) {
    return switch (value) {
      'always' => ProseWrap.always,
      'never' => ProseWrap.never,
      _ => ProseWrap.preserve,
    };
  }

  ProcessResult _processPaths(
    List<String> paths,
    OutputMode outputMode,
    FormatOptions options,
  ) {
    var result = ProcessResult.unchanged;

    for (final path in paths) {
      result = result.merge(_processPath(path, outputMode, options));
    }

    return result;
  }

  ProcessResult _processPath(
    String path,
    OutputMode outputMode,
    FormatOptions options, {
    IgnoreRules? parentRules,
  }) {
    final entityType = FileSystemEntity.typeSync(path);

    return switch (entityType) {
      FileSystemEntityType.notFound => _handleNotFound(path),
      FileSystemEntityType.directory => _processDirectory(
        path,
        outputMode,
        options,
        parentRules: parentRules,
      ),
      FileSystemEntityType.file => _processFile(path, outputMode, options),
      _ => ProcessResult.unchanged,
    };
  }

  ProcessResult _handleNotFound(String path) {
    stderr.writeln('Error: "$path" not found.');
    return ProcessResult.error;
  }

  ProcessResult _processDirectory(
    String dirPath,
    OutputMode outputMode,
    FormatOptions options, {
    IgnoreRules? parentRules,
  }) {
    final dir = Directory(dirPath);
    var result = ProcessResult.unchanged;

    // Load ignore rules for this directory and merge with parent rules
    var rules = IgnoreRules.loadFromDirectory(dirPath);
    if (parentRules != null) {
      rules = parentRules.merge(rules);
    }

    try {
      for (final entity in dir.listSync(recursive: false)) {
        final name = _basename(entity.path);
        final isDirectory = entity is Directory;

        // Check if should be ignored
        if (rules.shouldIgnore(
          name,
          _ignoredDirectories,
          isDirectory: isDirectory,
        )) {
          continue;
        }

        result = result.merge(
          _processEntity(entity, outputMode, options, rules),
        );
      }
    } catch (e) {
      stderr.writeln('Error analyzing directory "$dirPath": $e');
      return ProcessResult.error;
    }

    return result;
  }

  ProcessResult _processEntity(
    FileSystemEntity entity,
    OutputMode outputMode,
    FormatOptions options,
    IgnoreRules rules,
  ) {
    if (entity is Directory) {
      return _processDirectory(
        entity.path,
        outputMode,
        options,
        parentRules: rules,
      );
    }
    if (entity is File && _isFormattableFile(entity.path)) {
      return _processFile(entity.path, outputMode, options);
    }
    return ProcessResult.unchanged;
  }

  ProcessResult _processFile(
    String filePath,
    OutputMode outputMode,
    FormatOptions options,
  ) {
    if (!_isFormattableFile(filePath)) {
      return ProcessResult.unchanged;
    }

    try {
      final file = File(filePath);
      final content = file.readAsStringSync();
      final formatted = _formatContent(filePath, content, options);
      final changed = content != formatted;

      _outputResult(file, filePath, formatted, changed, outputMode);

      return changed ? ProcessResult.changed : ProcessResult.unchanged;
    } catch (e) {
      stderr.writeln('Error formatting "$filePath": $e');
      return ProcessResult.error;
    }
  }

  void _outputResult(
    File file,
    String filePath,
    String formatted,
    bool changed,
    OutputMode outputMode,
  ) {
    switch (outputMode) {
      case OutputMode.write:
        if (changed) {
          file.writeAsStringSync(formatted);
          stdout.writeln('Formatted $filePath');
        }
      case OutputMode.show:
        stdout.write(formatted);
      case OutputMode.json:
        stdout.writeln(jsonEncode({'path': filePath, 'source': formatted}));
      case OutputMode.none:
        break;
    }
  }

  bool _isFormattableFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.md') ||
        lowerPath.endsWith('.markdown') ||
        lowerPath.endsWith('.yaml') ||
        lowerPath.endsWith('.yml');
  }

  String _formatContent(
    String filePath,
    String content,
    FormatOptions options,
  ) {
    final lowerPath = filePath.toLowerCase();

    if (lowerPath.endsWith('.md') || lowerPath.endsWith('.markdown')) {
      return formatMarkdown(content, options: options);
    }

    if (lowerPath.endsWith('.yaml') || lowerPath.endsWith('.yml')) {
      return formatYaml(content, options: options);
    }

    return content;
  }
}

/// Extracts the basename from a file path.
String _basename(String path) {
  return Uri.file(path).pathSegments.lastWhere((s) => s.isNotEmpty);
}
