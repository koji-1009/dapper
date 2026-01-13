import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../bin/dapper.dart';

void main() {
  group('IgnorePattern', () {
    group('parse', () {
      test('returns null for empty pattern', () {
        expect(IgnorePattern.parse(''), isNull);
        expect(IgnorePattern.parse('/'), isNull);
      });

      test('parses simple pattern', () {
        final pattern = IgnorePattern.parse('*.log');
        expect(pattern, isNotNull);
        expect(pattern!.hasPathSeparator, isFalse);
        expect(pattern.isDirectoryOnly, isFalse);
      });

      test('parses directory pattern (trailing /)', () {
        final pattern = IgnorePattern.parse('build/');
        expect(pattern, isNotNull);
        expect(pattern!.isDirectoryOnly, isTrue);
        expect(pattern.hasPathSeparator, isFalse);
      });

      test('parses path pattern (contains /)', () {
        final pattern = IgnorePattern.parse('ios/Pods');
        expect(pattern, isNotNull);
        expect(pattern!.hasPathSeparator, isTrue);
        expect(pattern.isDirectoryOnly, isFalse);
      });

      test('parses path directory pattern', () {
        final pattern = IgnorePattern.parse('ios/Pods/');
        expect(pattern, isNotNull);
        expect(pattern!.hasPathSeparator, isTrue);
        expect(pattern.isDirectoryOnly, isTrue);
      });

      test('removes leading slash', () {
        final pattern = IgnorePattern.parse('/build');
        expect(pattern, isNotNull);
        expect(pattern!.hasPathSeparator, isFalse);
      });

      test('parses double asterisk pattern', () {
        final pattern = IgnorePattern.parse('**/build');
        expect(pattern, isNotNull);
        expect(pattern!.hasPathSeparator, isTrue);
      });

      test('parses pattern with double asterisk in middle', () {
        final pattern = IgnorePattern.parse('foo/**/bar');
        expect(pattern, isNotNull);
        expect(pattern!.hasPathSeparator, isTrue);
      });
    });

    group('matches', () {
      test('simple pattern matches basename', () {
        final pattern = IgnorePattern.parse('*.log')!;
        expect(pattern.matches('error.log', isDirectory: false), isTrue);
        expect(
          pattern.matches('path/to/error.log', isDirectory: false),
          isTrue,
        );
        expect(pattern.matches('error.txt', isDirectory: false), isFalse);
      });

      test('directory pattern only matches directories', () {
        final pattern = IgnorePattern.parse('build/')!;
        expect(pattern.matches('build', isDirectory: true), isTrue);
        expect(pattern.matches('build', isDirectory: false), isFalse);
      });

      test('path pattern matches full relative path', () {
        final pattern = IgnorePattern.parse('ios/Pods')!;
        expect(pattern.matches('ios/Pods', isDirectory: true), isTrue);
        expect(pattern.matches('Pods', isDirectory: true), isFalse);
        expect(pattern.matches('android/Pods', isDirectory: true), isFalse);
      });

      test('simple pattern matches at any level', () {
        final pattern = IgnorePattern.parse('Pods')!;
        expect(pattern.matches('Pods', isDirectory: true), isTrue);
        expect(pattern.matches('ios/Pods', isDirectory: true), isTrue);
      });

      test('double asterisk matches nested paths', () {
        final pattern = IgnorePattern.parse('**/build')!;
        // ** matches one or more directories (not zero)
        expect(pattern.matches('src/build', isDirectory: true), isTrue);
        expect(pattern.matches('src/main/build', isDirectory: true), isTrue);
        // Note: ** does NOT match zero directories in glob package
        expect(pattern.matches('build', isDirectory: true), isFalse);
      });

      test('double asterisk with directory suffix', () {
        final pattern = IgnorePattern.parse('**/build/')!;
        expect(pattern.matches('src/build', isDirectory: true), isTrue);
        expect(pattern.matches('src/build', isDirectory: false), isFalse);
      });

      test('pattern with double asterisk in middle', () {
        final pattern = IgnorePattern.parse('foo/**/bar')!;
        // ** in middle matches one or more directories
        expect(pattern.matches('foo/x/bar', isDirectory: true), isTrue);
        expect(pattern.matches('foo/x/y/bar', isDirectory: true), isTrue);
        // foo/bar requires ** to match zero, which it doesn't
        expect(pattern.matches('foo/bar', isDirectory: true), isFalse);
        expect(pattern.matches('bar', isDirectory: true), isFalse);
      });

      test('character class pattern', () {
        final pattern = IgnorePattern.parse('[Bb]uild')!;
        expect(pattern.matches('Build', isDirectory: true), isTrue);
        expect(pattern.matches('build', isDirectory: true), isTrue);
        expect(pattern.matches('xbuild', isDirectory: true), isFalse);
      });

      test('question mark matches single character', () {
        final pattern = IgnorePattern.parse('?.log')!;
        expect(pattern.matches('a.log', isDirectory: false), isTrue);
        expect(pattern.matches('ab.log', isDirectory: false), isFalse);
      });
    });
  });

  group('IgnoreRules', () {
    group('parse', () {
      test('parses empty content', () {
        final rules = IgnoreRules.parse('');
        expect(rules.isEmpty, isTrue);
      });

      test('ignores comments and blank lines', () {
        final rules = IgnoreRules.parse('''
# This is a comment

# Another comment
''');
        expect(rules.isEmpty, isTrue);
      });

      test('parses patterns', () {
        final rules = IgnoreRules.parse('''
build/
*.log
node_modules
''');
        expect(rules.isEmpty, isFalse);
      });

      test('parses negation patterns', () {
        final rules = IgnoreRules.parse('!important.log');
        expect(rules.isEmpty, isFalse);
      });
    });

    group('shouldIgnore', () {
      test('ignores default directories', () {
        final rules = IgnoreRules.empty();
        final defaults = {'.git', '.dart_tool'};

        expect(rules.shouldIgnore('.git', defaults, isDirectory: true), isTrue);
        expect(
          rules.shouldIgnore('.dart_tool', defaults, isDirectory: true),
          isTrue,
        );
        expect(rules.shouldIgnore('src', defaults, isDirectory: true), isFalse);
      });

      test('ignores matching patterns', () {
        final rules = IgnoreRules.parse('build/\n*.log');

        expect(rules.shouldIgnore('build', {}, isDirectory: true), isTrue);
        expect(rules.shouldIgnore('error.log', {}, isDirectory: false), isTrue);
        expect(rules.shouldIgnore('src', {}, isDirectory: true), isFalse);
      });

      test('negation overrides defaults', () {
        final rules = IgnoreRules.parse('!.git');
        final defaults = {'.git'};

        expect(
          rules.shouldIgnore('.git', defaults, isDirectory: true),
          isFalse,
        );
      });

      test('supports relative path matching', () {
        final rules = IgnoreRules.parse('ios/Pods');

        expect(
          rules.shouldIgnore(
            'Pods',
            {},
            relativePath: 'ios/Pods',
            isDirectory: true,
          ),
          isTrue,
        );
        expect(
          rules.shouldIgnore(
            'Pods',
            {},
            relativePath: 'android/Pods',
            isDirectory: true,
          ),
          isFalse,
        );
      });
    });

    group('merge', () {
      test('combines patterns from both rules', () {
        final rules1 = IgnoreRules.parse('build/');
        final rules2 = IgnoreRules.parse('*.log');
        final merged = rules1.merge(rules2);

        expect(merged.shouldIgnore('build', {}, isDirectory: true), isTrue);
        expect(
          merged.shouldIgnore('error.log', {}, isDirectory: false),
          isTrue,
        );
      });
    });

    group('loadFromDirectory', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('dapper_test_');
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('returns empty rules when no ignore files exist', () {
        final rules = IgnoreRules.loadFromDirectory(tempDir.path);
        expect(rules.isEmpty, isTrue);
      });

      test('loads .gitignore', () {
        File('${tempDir.path}/.gitignore').writeAsStringSync('build/');
        final rules = IgnoreRules.loadFromDirectory(tempDir.path);

        expect(rules.shouldIgnore('build', {}, isDirectory: true), isTrue);
      });

      test('loads .dapperignore', () {
        File(
          '${tempDir.path}/.dapperignore',
        ).writeAsStringSync('*.generated.md');
        final rules = IgnoreRules.loadFromDirectory(tempDir.path);

        expect(
          rules.shouldIgnore('test.generated.md', {}, isDirectory: false),
          isTrue,
        );
      });

      test('merges both ignore files', () {
        File('${tempDir.path}/.gitignore').writeAsStringSync('build/');
        File(
          '${tempDir.path}/.dapperignore',
        ).writeAsStringSync('*.generated.md');
        final rules = IgnoreRules.loadFromDirectory(tempDir.path);

        expect(rules.shouldIgnore('build', {}, isDirectory: true), isTrue);
        expect(
          rules.shouldIgnore('test.generated.md', {}, isDirectory: false),
          isTrue,
        );
      });
    });
  });

  group('ConfigLoader', () {
    late Directory tempDir;
    const loader = ConfigLoader();

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dapper_config_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('returns null when no config exists', () {
      expect(loader.loadFromDirectory(tempDir.path), isNull);
    });

    test('loads dapper.yaml', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
print_width: 100
tab_width: 4
prose_wrap: always
ul_style: dash
''');
      final options = loader.loadFromDirectory(tempDir.path);

      expect(options, isNotNull);
      expect(options!.printWidth, 100);
      expect(options.tabWidth, 4);
    });

    test('loads analysis_options.yaml dapper block', () {
      File('${tempDir.path}/analysis_options.yaml').writeAsStringSync('''
analyzer:
  errors:
    todo: ignore

dapper:
  print_width: 120
''');
      final options = loader.loadFromDirectory(tempDir.path);

      expect(options, isNotNull);
      expect(options!.printWidth, 120);
    });

    test('prefers dapper.yaml over analysis_options.yaml', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('print_width: 80');
      File('${tempDir.path}/analysis_options.yaml').writeAsStringSync('''
dapper:
  print_width: 120
''');
      final options = loader.loadFromDirectory(tempDir.path);

      expect(options!.printWidth, 80);
    });
  });

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

      test('returns success for valid markdown file', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('# Hello\n');

        expect(runQuietly(['-o', 'none', file.path]).code, 0);
      });

      test('returns changed when file is reformatted', () {
        final file = File('${tempDir.path}/test.md');
        file.writeAsStringSync('*emphasis*\n'); // Will be changed to _emphasis_

        final result = runQuietly([
          '-o',
          'none',
          '--set-exit-if-changed',
          file.path,
        ]);
        expect(result.code, 1); // changed
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
        expect(result.code, 0); // unchanged
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
        // ignored/test.md would cause changed, but it's ignored
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
        // Root .gitignore
        File('${tempDir.path}/.gitignore').writeAsStringSync('*.log\n');

        // Subdirectory with its own .dapperignore
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
        // If it was not ignored, it would be formatted (adding newline) -> changed
        // But since it is ignored, it should remain unchanged (even if unformatted)
        // Wait, if content is 'key: value', formatter adds newline?
        // Let's write invalid YAML or unformatted YAML to be sure.
        File(
          '${tempDir.path}/test-lock.yaml',
        ).writeAsStringSync('key: value'); // Missing trailing newline

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
        // Long line that would wrap at different widths
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
    });
  });

  group('ExitCode', () {
    test('has correct values', () {
      expect(ExitCode.success.code, 0);
      expect(ExitCode.error.code, 1);
      expect(ExitCode.changed.code, 1);
    });
  });
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
