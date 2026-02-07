import 'dart:convert';
import 'dart:io' as io show FileSystemEntityType;
import 'dart:io' hide File, Directory, FileSystemEntity, FileSystemEntityType;

import 'package:args/args.dart';

import '../src/markdown/markdown_formatter.dart';
import '../src/options.dart';
import '../src/yaml/yaml_formatter.dart';
import 'config_loader.dart';
import 'exit_code.dart';
import 'file_system.dart';
import 'ignore_rules.dart';
import 'output_mode.dart';
import 'process_result.dart';

/// Runs the Dapper CLI.
void run(List<String> arguments, {DapperCli cli = const DapperCli()}) {
  try {
    final result = cli.run(arguments);
    exitCode = result.code;
  } catch (e, stack) {
    stderr.writeln('Unexpected error: $e');
    stderr.writeln(stack);
    exitCode = ExitCode.error.code;
  }
}

/// Command-line interface for the Dapper formatter.
class DapperCli {
  /// Creates a new CLI instance.
  const DapperCli({
    this.configLoader = const ConfigLoader(),
    this.fileSystem = const FileSystem(),
  });

  /// Configuration loader for format options.
  final ConfigLoader configLoader;

  /// File system abstraction for file operations.
  final FileSystem fileSystem;

  static const _noFilesError = 'Error: No files or directories specified.';

  /// Directories to ignore during recursive scanning.
  static const _ignoredDirectories = {
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    '.fvm',
  };

  /// Default ignore rules.
  static final _defaultIgnoreRules = IgnoreRules.parse('*-lock.yaml');

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

      final stopwatch = Stopwatch()..start();
      final result = _processPaths(paths, outputMode, options);
      stopwatch.stop();

      if (outputMode == OutputMode.write) {
        final elapsed = stopwatch.elapsed.inMilliseconds / 1000.0;
        final timeStr = elapsed.toStringAsFixed(2);
        final sentence = result.changedFiles == 0
            ? 'Formatted ${result.totalFiles} files'
            : 'Formatted ${result.totalFiles} files (${result.changedFiles} changed)';
        stdout.writeln('$sentence in $timeStr seconds.');
      }

      if (result.status == ProcessResult.error) {
        return ExitCode.error;
      }
      if (setExitIfChanged && result.status == ProcessResult.changed) {
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
      fileSystem.currentDirectory,
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

  _ProcessResult _processPaths(
    List<String> paths,
    OutputMode outputMode,
    FormatOptions options,
  ) {
    var result = (
      status: ProcessResult.unchanged,
      totalFiles: 0,
      changedFiles: 0,
    );

    for (final path in paths) {
      result = _mergeResults(result, _processPath(path, outputMode, options));
    }

    return result;
  }

  _ProcessResult _processPath(
    String path,
    OutputMode outputMode,
    FormatOptions options, {
    IgnoreRules? parentRules,
  }) {
    final entityType = fileSystem.getType(path);

    return switch (entityType) {
      io.FileSystemEntityType.notFound => _handleNotFound(path),
      io.FileSystemEntityType.directory => _processDirectory(
        path,
        outputMode,
        options,
        parentRules: parentRules,
      ),
      io.FileSystemEntityType.file => _processFile(path, outputMode, options),
      _ => (status: ProcessResult.unchanged, totalFiles: 0, changedFiles: 0),
    };
  }

  _ProcessResult _handleNotFound(String path) {
    stderr.writeln('Error: "$path" not found.');
    return (status: ProcessResult.error, totalFiles: 0, changedFiles: 0);
  }

  _ProcessResult _processDirectory(
    String dirPath,
    OutputMode outputMode,
    FormatOptions options, {
    IgnoreRules? parentRules,
    String? relativeBasePath,
  }) {
    var result = (
      status: ProcessResult.unchanged,
      totalFiles: 0,
      changedFiles: 0,
    );

    // Load ignore rules for this directory and merge with parent rules
    var rules = IgnoreRules.loadFromDirectory(dirPath);
    if (parentRules != null) {
      rules = parentRules.merge(rules);
    } else {
      // If no parent rules, this is a root directory scan.
      // Merge with default rules.
      rules = _defaultIgnoreRules.merge(rules);
    }

    try {
      for (final entry in fileSystem.listDirectory(dirPath)) {
        final name = basename(entry.path);

        // Build relative path for path-based pattern matching
        final relativePath = relativeBasePath != null
            ? '$relativeBasePath/$name'
            : name;

        // Check if should be ignored
        if (rules.shouldIgnore(
          name,
          _ignoredDirectories,
          relativePath: relativePath,
          isDirectory: entry.isDirectory,
        )) {
          continue;
        }

        result = _mergeResults(
          result,
          _processEntry(
            entry,
            outputMode,
            options,
            rules,
            relativePath: relativePath,
          ),
        );
      }
    } catch (e) {
      stderr.writeln('Error analyzing directory "$dirPath": $e');
      return (status: ProcessResult.error, totalFiles: 0, changedFiles: 0);
    }

    return result;
  }

  _ProcessResult _processEntry(
    FileEntry entry,
    OutputMode outputMode,
    FormatOptions options,
    IgnoreRules rules, {
    required String relativePath,
  }) {
    if (entry.isDirectory) {
      return _processDirectory(
        entry.path,
        outputMode,
        options,
        parentRules: rules,
        relativeBasePath: relativePath,
      );
    }
    if (_isFormattableFile(entry.path)) {
      return _processFile(entry.path, outputMode, options);
    }
    return (status: ProcessResult.unchanged, totalFiles: 0, changedFiles: 0);
  }

  _ProcessResult _processFile(
    String filePath,
    OutputMode outputMode,
    FormatOptions options,
  ) {
    if (!_isFormattableFile(filePath)) {
      return (status: ProcessResult.unchanged, totalFiles: 0, changedFiles: 0);
    }

    try {
      final content = fileSystem.readFile(filePath);
      final formatted = _formatContent(filePath, content, options);
      final changed = content != formatted;

      _outputResult(filePath, formatted, changed, outputMode);

      return (
        status: changed ? ProcessResult.changed : ProcessResult.unchanged,
        totalFiles: 1,
        changedFiles: changed ? 1 : 0,
      );
    } catch (e) {
      stderr.writeln('Error formatting "$filePath": $e');
      return (status: ProcessResult.error, totalFiles: 1, changedFiles: 0);
    }
  }

  void _outputResult(
    String filePath,
    String formatted,
    bool changed,
    OutputMode outputMode,
  ) {
    switch (outputMode) {
      case OutputMode.write:
        if (changed) {
          fileSystem.writeFile(filePath, formatted);
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

  _ProcessResult _mergeResults(_ProcessResult a, _ProcessResult b) {
    return (
      status: a.status.merge(b.status),
      totalFiles: a.totalFiles + b.totalFiles,
      changedFiles: a.changedFiles + b.changedFiles,
    );
  }
}

typedef _ProcessResult = ({
  ProcessResult status,
  int totalFiles,
  int changedFiles,
});
