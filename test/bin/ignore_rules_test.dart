import 'dart:io';

import 'package:dapper/bin.dart';
import 'package:test/test.dart';

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
        expect(pattern.matches('src/build', isDirectory: true), isTrue);
        expect(pattern.matches('src/main/build', isDirectory: true), isTrue);
        expect(pattern.matches('build', isDirectory: true), isFalse);
      });

      test('double asterisk with directory suffix', () {
        final pattern = IgnorePattern.parse('**/build/')!;
        expect(pattern.matches('src/build', isDirectory: true), isTrue);
        expect(pattern.matches('src/build', isDirectory: false), isFalse);
      });

      test('pattern with double asterisk in middle', () {
        final pattern = IgnorePattern.parse('foo/**/bar')!;
        expect(pattern.matches('foo/x/bar', isDirectory: true), isTrue);
        expect(pattern.matches('foo/x/y/bar', isDirectory: true), isTrue);
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
}
