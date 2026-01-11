// Dapper CLI - Format Markdown and YAML files.
//
// Usage: dapper [options] <files or directories...>

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dapper/dapper.dart';
import 'package:yaml/yaml.dart';

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
enum ProcessResult { unchanged, changed, error }

void main(List<String> arguments) {
  const cli = DapperCli();
  exit(cli.run(arguments).code);
}

/// Command-line interface for the Dapper formatter.
class DapperCli {
  const DapperCli();

  static const _noFilesError = 'Error: No files or directories specified.';

  /// Directories to ignore during recursive scanning.
  static const _ignoredDirectories = {
    '.git',
    '.dart_tool',
    '.idea',
    '.vscode',
    '.fvm',
    'build',
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

    final parser = ArgParser()
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

      final (hasChanges, hasErrors) = _processPaths(paths, outputMode, options);

      if (hasErrors) {
        return ExitCode.error;
      }
      if (setExitIfChanged && hasChanges) {
        return ExitCode.changed;
      }
      return ExitCode.success;
    } on FormatException catch (e) {
      stderr.writeln('Error: ${e.message}');
      _printUsage(parser.usage);
      return ExitCode.error;
    }
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
    final configOptions = _loadConfigFromDirectory(Directory.current.path);

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
      ulStyle: configOptions?.ulStyle ?? UnorderedListStyle.dash,
    );
  }

  ProseWrap _parseProseWrap(String value) {
    return switch (value) {
      'always' => ProseWrap.always,
      'never' => ProseWrap.never,
      _ => ProseWrap.preserve,
    };
  }

  (bool, bool) _processPaths(
    List<String> paths,
    OutputMode outputMode,
    FormatOptions options,
  ) {
    var hasChanges = false;
    var hasErrors = false;

    for (final path in paths) {
      final result = _processPath(path, outputMode, options);
      if (result == ProcessResult.changed) {
        hasChanges = true;
      } else if (result == ProcessResult.error) {
        hasErrors = true;
      }
    }

    return (hasChanges, hasErrors);
  }

  ProcessResult _processPath(
    String path,
    OutputMode outputMode,
    FormatOptions options,
  ) {
    final entity = FileSystemEntity.typeSync(path);

    return switch (entity) {
      FileSystemEntityType.notFound => _handleNotFound(path),
      FileSystemEntityType.directory => _processDirectory(
        path,
        outputMode,
        options,
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
    FormatOptions options,
  ) {
    final dir = Directory(dirPath);
    var result = ProcessResult.unchanged;

    try {
      for (final entity in dir.listSync(recursive: false)) {
        final name = _basename(entity.path);

        if (_ignoredDirectories.contains(name)) {
          continue;
        }

        final subResult = _processEntity(entity, outputMode, options);
        result = _mergeResults(result, subResult);
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
  ) {
    if (entity is Directory) {
      return _processDirectory(entity.path, outputMode, options);
    }
    if (entity is File && _isFormattableFile(entity.path)) {
      return _processFile(entity.path, outputMode, options);
    }
    return ProcessResult.unchanged;
  }

  ProcessResult _mergeResults(ProcessResult current, ProcessResult newResult) {
    if (newResult == ProcessResult.error) {
      return ProcessResult.error;
    }
    if (newResult == ProcessResult.changed && current != ProcessResult.error) {
      return ProcessResult.changed;
    }
    return current;
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

  FormatOptions? _loadConfigFromDirectory(String directoryPath) {
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
        _parseConfigInt(map['print_width']) ??
        _parseConfigInt(map['printWidth']);
    final tabWidth =
        _parseConfigInt(map['tab_width']) ?? _parseConfigInt(map['tabWidth']);
    final proseWrap =
        _parseConfigProseWrap(map['prose_wrap']) ??
        _parseConfigProseWrap(map['proseWrap']);
    final ulStyle =
        _parseConfigUlStyle(map['ul_style']) ??
        _parseConfigUlStyle(map['ulStyle']);

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
      ulStyle: ulStyle ?? UnorderedListStyle.dash,
    );
  }

  int? _parseConfigInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  ProseWrap? _parseConfigProseWrap(dynamic value) {
    if (value is! String) return null;
    return switch (value.toLowerCase()) {
      'always' => ProseWrap.always,
      'never' => ProseWrap.never,
      'preserve' => ProseWrap.preserve,
      _ => null,
    };
  }

  UnorderedListStyle? _parseConfigUlStyle(dynamic value) {
    if (value is! String) return null;
    return switch (value.toLowerCase()) {
      'dash' || '-' => UnorderedListStyle.dash,
      'asterisk' || '*' => UnorderedListStyle.asterisk,
      'plus' || '+' => UnorderedListStyle.plus,
      _ => null,
    };
  }
}

/// Extracts the basename from a file path.
String _basename(String path) {
  return Uri.file(path).pathSegments.lastWhere((s) => s.isNotEmpty);
}
