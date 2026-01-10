// Dapper CLI - Format Markdown and YAML files.
//
// Usage: dapper [options] <files or directories...>

import 'dart:io';

import 'package:args/args.dart';
import 'package:dapper/dapper.dart';

/// Exit codes
const _exitSuccess = 0;
const _exitError = 1;
const _exitChanged = 1;

void main(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show all options and flags with --help.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      defaultsTo: 'write',
      allowed: ['write', 'show', 'none'],
      help: 'Set where to write formatted output.',
      valueHelp: 'mode',
      allowedHelp: {
        'write': 'Overwrite formatted files on disk.',
        'show': 'Print code to terminal.',
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
      _printUsage(parser, verbose: results['verbose'] as bool);
      exit(_exitSuccess);
    }

    final paths = results.rest;
    if (paths.isEmpty) {
      stderr.writeln('Error: No files or directories specified.');
      stderr.writeln();
      _printUsage(parser);
      exit(_exitError);
    }

    final outputMode = results['output'] as String;
    final setExitIfChanged = results['set-exit-if-changed'] as bool;
    final printWidth = int.tryParse(results['print-width'] as String) ?? 80;
    final proseWrapStr = results['prose-wrap'] as String;
    final proseWrap = switch (proseWrapStr) {
      'always' => ProseWrap.always,
      'never' => ProseWrap.never,
      _ => ProseWrap.preserve,
    };

    final options = FormatOptions(printWidth: printWidth, proseWrap: proseWrap);

    var hasChanges = false;
    var hasErrors = false;

    for (final path in paths) {
      final result = _processPath(path, outputMode, options);
      if (result == _ProcessResult.changed) {
        hasChanges = true;
      } else if (result == _ProcessResult.error) {
        hasErrors = true;
      }
    }

    if (hasErrors) {
      exit(_exitError);
    }

    if (setExitIfChanged && hasChanges) {
      exit(_exitChanged);
    }

    exit(_exitSuccess);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printUsage(parser);
    exit(_exitError);
  }
}

void _printUsage(ArgParser parser, {bool verbose = false}) {
  stdout.writeln('Idiomatically format Markdown and YAML files.');
  stdout.writeln();
  stdout.writeln('Usage: dapper [options] <files or directories...>');
  stdout.writeln();
  stdout.writeln(parser.usage);
}

enum _ProcessResult { unchanged, changed, error }

_ProcessResult _processPath(
  String path,
  String outputMode,
  FormatOptions options,
) {
  final entity = FileSystemEntity.typeSync(path);

  if (entity == FileSystemEntityType.notFound) {
    stderr.writeln('Error: "$path" not found.');
    return _ProcessResult.error;
  }

  if (entity == FileSystemEntityType.directory) {
    return _processDirectory(path, outputMode, options);
  }

  if (entity == FileSystemEntityType.file) {
    return _processFile(path, outputMode, options);
  }

  return _ProcessResult.unchanged;
}

// Directories to ignore during recursive scanning.
// These typically contain generated files, build artifacts, or IDE settings
// that should not be formatted.
// Note: .github is NOT included here because we want to format workflow files.
const _ignoredDirectories = {
  '.git',
  '.dart_tool',
  '.idea',
  '.vscode',
  '.fvm',
  'build',
};

_ProcessResult _processDirectory(
  String dirPath,
  String outputMode,
  FormatOptions options,
) {
  final dir = Directory(dirPath);
  var result = _ProcessResult.unchanged;

  try {
    for (final entity in dir.listSync(recursive: false)) {
      final name = Uri.file(
        entity.path,
      ).pathSegments.lastWhere((s) => s.isNotEmpty);

      if (_ignoredDirectories.contains(name)) {
        continue;
      }

      if (entity is Directory) {
        final subResult = _processDirectory(entity.path, outputMode, options);
        if (subResult == _ProcessResult.error) {
          result = _ProcessResult.error;
        } else if (subResult == _ProcessResult.changed &&
            result != _ProcessResult.error) {
          result = _ProcessResult.changed;
        }
      } else if (entity is File && _isFormattableFile(entity.path)) {
        final fileResult = _processFile(entity.path, outputMode, options);
        if (fileResult == _ProcessResult.error) {
          result = _ProcessResult.error;
        } else if (fileResult == _ProcessResult.changed &&
            result != _ProcessResult.error) {
          result = _ProcessResult.changed;
        }
      }
    }
  } catch (e) {
    stderr.writeln('Error analyzing directory "$dirPath": $e');
    return _ProcessResult.error;
  }

  return result;
}

_ProcessResult _processFile(
  String filePath,
  String outputMode,
  FormatOptions options,
) {
  if (!_isFormattableFile(filePath)) {
    return _ProcessResult.unchanged;
  }

  try {
    final file = File(filePath);
    final content = file.readAsStringSync();
    final formatted = _formatFile(filePath, content, options);

    final changed = content != formatted;

    switch (outputMode) {
      case 'write':
        if (changed) {
          file.writeAsStringSync(formatted);
          stdout.writeln('Formatted $filePath');
        }
      case 'show':
        stdout.write(formatted);
      case 'none':
        // Discard output, just check for changes
        break;
    }

    return changed ? _ProcessResult.changed : _ProcessResult.unchanged;
  } catch (e) {
    stderr.writeln('Error formatting "$filePath": $e');
    return _ProcessResult.error;
  }
}

bool _isFormattableFile(String path) {
  final lowerPath = path.toLowerCase();
  return lowerPath.endsWith('.md') ||
      lowerPath.endsWith('.markdown') ||
      lowerPath.endsWith('.yaml') ||
      lowerPath.endsWith('.yml');
}

String _formatFile(String filePath, String content, FormatOptions options) {
  final lowerPath = filePath.toLowerCase();

  if (lowerPath.endsWith('.md') || lowerPath.endsWith('.markdown')) {
    return formatMarkdown(content, options: options);
  }

  if (lowerPath.endsWith('.yaml') || lowerPath.endsWith('.yml')) {
    return formatYaml(content, options: options);
  }

  return content;
}
