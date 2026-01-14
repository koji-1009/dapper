import 'dart:convert';
import 'dart:io';

import 'package:dapper/bin.dart';
import 'package:test/test.dart';

void main() {
  group('ProcessResult', () {
    test('merge prioritizes error', () {
      expect(
        ProcessResult.unchanged.merge(ProcessResult.error),
        ProcessResult.error,
      );
      expect(
        ProcessResult.changed.merge(ProcessResult.error),
        ProcessResult.error,
      );
      expect(
        ProcessResult.error.merge(ProcessResult.unchanged),
        ProcessResult.error,
      );
    });

    test('merge prioritizes changed over unchanged', () {
      expect(
        ProcessResult.unchanged.merge(ProcessResult.changed),
        ProcessResult.changed,
      );
      expect(
        ProcessResult.changed.merge(ProcessResult.unchanged),
        ProcessResult.changed,
      );
    });

    test('merge returns unchanged when both unchanged', () {
      expect(
        ProcessResult.unchanged.merge(ProcessResult.unchanged),
        ProcessResult.unchanged,
      );
    });
  });

  group('OutputMode', () {
    test('fromString parses valid modes', () {
      expect(OutputMode.fromString('write'), OutputMode.write);
      expect(OutputMode.fromString('show'), OutputMode.show);
      expect(OutputMode.fromString('json'), OutputMode.json);
      expect(OutputMode.fromString('none'), OutputMode.none);
    });

    test('fromString defaults to write for unknown', () {
      expect(OutputMode.fromString('unknown'), OutputMode.write);
    });
  });

  group('ExitCode', () {
    test('has correct values', () {
      expect(ExitCode.success.code, 0);
      expect(ExitCode.error.code, 1);
      expect(ExitCode.changed.code, 1);
    });
  });

  group('DapperCli', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dapper_cli_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    /// Runs CLI and suppresses stdout/stderr output.
    ExitCode runQuietly(List<String> args) {
      final result = IOOverrides.runZoned(
        () => const DapperCli().run(args),
        stdout: () => _NullStdout(),
        stderr: () => _NullStdout(),
      );
      return result;
    }

    group('run', () {
      test('returns error when no arguments', () {
        expect(runQuietly([]).code, 1);
      });

      test('returns success for --help', () {
        expect(runQuietly(['--help']).code, 0);
      });

      test('returns error when path not found', () {
        expect(runQuietly(['nonexistent_path']).code, 1);
      });

      test('returns error for invalid option', () {
        // Unknown flag causes FormatException
        expect(runQuietly(['--invalid-option']).code, 1);
      });

      test('returns error when only flags but no paths', () {
        // Has arguments but no paths (rest is empty)
        expect(runQuietly(['-o', 'none']).code, 1);
      });

      test('returns success for valid markdown file', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('# Hello\n');

        expect(runQuietly(['-o', 'none', file.path]).code, 0);
      });

      test('returns changed when file is reformatted', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('*emphasis*\n');

        final result = runQuietly([
          '-o',
          'none',
          '--set-exit-if-changed',
          file.path,
        ]);
        expect(result.code, 1);
      });

      test('returns success when file is already formatted', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('# Hello\n');

        final result = runQuietly([
          '-o',
          'none',
          '--set-exit-if-changed',
          file.path,
        ]);
        expect(result.code, 0);
      });
    });

    group('directory traversal', () {
      test('processes markdown files in directory', () {
        File('${tempDir.path}/test.md').writeAsStringSync('# Test\n');
        File('${tempDir.path}/other.txt').writeAsStringSync('not markdown');

        expect(runQuietly(['-o', 'none', tempDir.path]).code, 0);
      });

      test('ignores default directories', () {
        Directory('${tempDir.path}/.git').createSync();
        File('${tempDir.path}/.git/config.md').writeAsStringSync('# Git\n');
        File('${tempDir.path}/test.md').writeAsStringSync('# Test\n');

        expect(runQuietly(['-o', 'none', tempDir.path]).code, 0);
      });

      test('respects .gitignore patterns', () {
        File('${tempDir.path}/.gitignore').writeAsStringSync('ignored/\n');
        Directory('${tempDir.path}/ignored').createSync();
        File(
          '${tempDir.path}/ignored/test.md',
        ).writeAsStringSync('*unformatted*\n');
        File('${tempDir.path}/test.md').writeAsStringSync('# Test\n');

        final result = runQuietly([
          '-o',
          'none',
          '--set-exit-if-changed',
          tempDir.path,
        ]);
        expect(result.code, 0);
      });

      test('respects .dapperignore patterns', () {
        File('${tempDir.path}/.dapperignore').writeAsStringSync('*.skip.md\n');
        File(
          '${tempDir.path}/test.skip.md',
        ).writeAsStringSync('*unformatted*\n');
        File('${tempDir.path}/test.md').writeAsStringSync('# Test\n');

        final result = runQuietly([
          '-o',
          'none',
          '--set-exit-if-changed',
          tempDir.path,
        ]);
        expect(result.code, 0);
      });

      test('supports path-based ignore patterns', () {
        File('${tempDir.path}/.gitignore').writeAsStringSync('sub/ignored\n');
        Directory('${tempDir.path}/sub').createSync();
        Directory('${tempDir.path}/sub/ignored').createSync();
        File(
          '${tempDir.path}/sub/ignored/test.md',
        ).writeAsStringSync('*unformatted*\n');
        File('${tempDir.path}/test.md').writeAsStringSync('# Test\n');

        final result = runQuietly([
          '-o',
          'none',
          '--set-exit-if-changed',
          tempDir.path,
        ]);
        expect(result.code, 0);
      });

      test('nested ignore files work correctly', () {
        File('${tempDir.path}/.gitignore').writeAsStringSync('*.log\n');
        Directory('${tempDir.path}/sub').createSync();
        File('${tempDir.path}/sub/.dapperignore').writeAsStringSync('local/\n');
        Directory('${tempDir.path}/sub/local').createSync();
        File(
          '${tempDir.path}/sub/local/test.md',
        ).writeAsStringSync('*unformatted*\n');
        File('${tempDir.path}/test.md').writeAsStringSync('# Test\n');

        final result = runQuietly([
          '-o',
          'none',
          '--set-exit-if-changed',
          tempDir.path,
        ]);
        expect(result.code, 0);
      });

      test('ignores *-lock.yaml files by default', () {
        File('${tempDir.path}/test-lock.yaml').writeAsStringSync('key: value');

        final result = runQuietly([
          '-o',
          'none',
          '--set-exit-if-changed',
          tempDir.path,
        ]);
        expect(result.code, 0);
      });
    });

    group('options', () {
      test('respects print-width option', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync(
          'This is a very long line that would need to be wrapped at some point.\n',
        );

        final result = runQuietly([
          '-o',
          'none',
          '--print-width',
          '40',
          file.path,
        ]);
        expect(result.code, 0);
      });

      test('respects prose-wrap option', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('Short.\n');

        final result = runQuietly([
          '-o',
          'none',
          '--prose-wrap',
          'preserve',
          file.path,
        ]);
        expect(result.code, 0);
      });

      test('uses config file options', () {
        File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
print_width: 40
tab_width: 4
prose_wrap: always
ul_style: dash
''');
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('# Test\n');

        // Run from the temp directory to pick up config
        final prevDir = Directory.current;
        Directory.current = tempDir;
        try {
          final result = runQuietly(['-o', 'none', 'test.md']);
          expect(result.code, 0);
        } finally {
          Directory.current = prevDir;
        }
      });
    });

    group('output modes', () {
      test('write mode writes to file', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('*emphasis*\n');

        runQuietly(['-o', 'write', file.path]);

        // File should be updated
        expect(file.readAsStringSync(), '_emphasis_\n');
      });

      test('show mode outputs to stdout', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('# Hello\n');

        // Just ensure it doesn't error
        expect(runQuietly(['-o', 'show', file.path]).code, 0);
      });

      test('json mode outputs JSON', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('# Hello\n');

        expect(runQuietly(['-o', 'json', file.path]).code, 0);
      });
    });

    group('yaml formatting', () {
      test('formats yaml files', () {
        final file = File('${tempDir.path}/test.yaml');
        file.writeAsStringSync('key: value\n');

        expect(runQuietly(['-o', 'none', file.path]).code, 0);
      });

      test('formats yml files', () {
        final file = File('${tempDir.path}/test.yml');
        file.writeAsStringSync('key: value\n');

        expect(runQuietly(['-o', 'none', file.path]).code, 0);
      });
    });
  });

  // Additional tests with mock file system
  _testWithMockFileSystem();
}

/// A stdout/stderr that discards all output.
class _NullStdout implements Stdout {
  @override
  void write(Object? object) {}

  @override
  void writeln([Object? object = '']) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void add(List<int> data) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) => Future.value();

  @override
  Future flush() => Future.value();

  @override
  Future close() => Future.value();

  @override
  Future get done => Future.value();

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding encoding) {}

  @override
  bool get hasTerminal => false;

  @override
  IOSink get nonBlocking => this;

  @override
  bool get supportsAnsiEscapes => false;

  @override
  int get terminalColumns => 80;

  @override
  int get terminalLines => 24;

  @override
  String get lineTerminator => '\n';

  @override
  set lineTerminator(String terminator) {}
}

/// Mock file system for testing error cases.
class _MockFileSystem implements FileSystem {
  final FileSystemEntityType Function(String)? onGetType;
  final List<FileEntry> Function(String)? onListDirectory;
  final String Function(String)? onReadFile;

  _MockFileSystem({this.onGetType, this.onListDirectory, this.onReadFile});

  @override
  FileSystemEntityType getType(String path) {
    if (onGetType != null) return onGetType!(path);
    return FileSystemEntityType.notFound;
  }

  @override
  List<FileEntry> listDirectory(String path) {
    if (onListDirectory != null) return onListDirectory!(path);
    return [];
  }

  @override
  String readFile(String path) {
    if (onReadFile != null) return onReadFile!(path);
    throw Exception('File not found');
  }

  @override
  void writeFile(String path, String content) {}

  @override
  String get currentDirectory => '/mock';
}

void _testWithMockFileSystem() {
  group('DapperCli with mock FileSystem', () {
    ExitCode runWithMock(List<String> args, FileSystem fs) {
      return IOOverrides.runZoned(
        () => DapperCli(fileSystem: fs).run(args),
        stdout: () => _NullStdout(),
        stderr: () => _NullStdout(),
      );
    }

    test('returns error when directory listing fails', () {
      final mockFs = _MockFileSystem(
        onGetType: (path) => FileSystemEntityType.directory,
        onListDirectory: (path) => throw Exception('Permission denied'),
      );

      final result = runWithMock(['-o', 'none', '/some/dir'], mockFs);
      expect(result.code, 1);
    });

    test('returns error when file read fails', () {
      final mockFs = _MockFileSystem(
        onGetType: (path) => FileSystemEntityType.file,
        onReadFile: (path) => throw Exception('Cannot read file'),
      );

      final result = runWithMock(['-o', 'none', '/some/file.md'], mockFs);
      expect(result.code, 1);
    });

    test('handles file formatting successfully', () {
      final mockFs = _MockFileSystem(
        onGetType: (path) => FileSystemEntityType.file,
        onReadFile: (path) => '# Hello\n',
      );

      final result = runWithMock(['-o', 'none', '/some/file.md'], mockFs);
      expect(result.code, 0);
    });
  });
}
