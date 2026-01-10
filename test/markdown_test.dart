/// Tests for MarkdownFormatter public API.
library;

import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownFormatter', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

    test('formats empty string', () {
      expect(formatter.format(''), '');
    });

    test('formats heading', () {
      final result = formatter.format('# Hello World');
      expect(result.trim(), '# Hello World');
    });

    test('formats paragraph', () {
      final result = formatter.format('Hello world');
      expect(result.trim(), 'Hello world');
    });

    test('normalizes emphasis * to _', () {
      final result = formatter.format('*hello*');
      expect(result.trim(), '_hello_');
    });

    test('preserves strong **', () {
      final result = formatter.format('**hello**');
      expect(result.trim(), '**hello**');
    });

    test('formats unordered list', () {
      final result = formatter.format('- item 1\n- item 2');
      expect(result, contains('- item 1'));
      expect(result, contains('- item 2'));
    });

    test('formats ordered list', () {
      final result = formatter.format('1. first\n2. second');
      expect(result, contains('1. first'));
      expect(result, contains('2. second'));
    });

    test('formats code block', () {
      final input = '''
```dart
void main() {}
```
''';
      final result = formatter.format(input);
      expect(result, contains('```dart'));
      expect(result, contains('void main() {}'));
    });

    test('formats inline code', () {
      final result = formatter.format('Use `code` here');
      expect(result, contains('`code`'));
    });

    test('formats link', () {
      final result = formatter.format('[text](https://example.com)');
      expect(result, contains('[text](https://example.com)'));
    });

    test('formats horizontal rule as ---', () {
      final result = formatter.format('---');
      expect(result.trim(), '---');
    });

    test('formats blockquote', () {
      final result = formatter.format('> quoted text');
      expect(result, contains('> quoted text'));
    });

    group('with proseWrap always', () {
      setUp(() {
        formatter = MarkdownFormatter(
          const FormatOptions(proseWrap: ProseWrap.always, printWidth: 40),
        );
      });

      test('wraps long paragraphs', () {
        final input =
            'This is a very long paragraph that should be wrapped at the specified width.';
        final result = formatter.format(input);
        final lines = result.trim().split('\n');
        expect(lines.length, greaterThan(1));
        for (final line in lines) {
          expect(line.length, lessThanOrEqualTo(40));
        }
      });
    });

    group('Front matter', () {
      test('preserves front matter during formatting', () {
        final input = '''---
title: Test
---
# Hello

*world*
''';
        final result = formatter.format(input);
        expect(result, contains('---'));
        expect(result, contains('title: Test'));
        expect(result, contains('# Hello'));
        expect(result, contains('_world_'));
      });
    });

    group('Definition lists', () {
      test('formats definition lists', () {
        final input = '''Term 1
: Definition 1

Term 2
: Definition 2a
: Definition 2b
''';
        final result = formatter.format(input);
        expect(result, contains('Term 1'));
        expect(result, contains(': Definition 1'));
        expect(result, contains('Term 2'));
        expect(result, contains(': Definition 2a'));
        expect(result, contains(': Definition 2b'));
      });
    });

    group('Setext headings', () {
      test('formats setext h1 to ATX', () {
        final result = formatter.format('Heading\n=======');
        expect(result.trim(), '# Heading');
      });

      test('formats setext h2 to ATX', () {
        final result = formatter.format('Heading\n-------');
        expect(result.trim(), '## Heading');
      });
    });

    group('Deep nesting', () {
      test('handles 5 levels of list nesting', () {
        final input = '''- L1
  - L2
    - L3
      - L4
        - L5
''';
        final result = formatter.format(input);
        expect(result, contains('- L1'));
        expect(result, contains('- L2'));
        expect(result, contains('- L3'));
        expect(result, contains('- L4'));
        expect(result, contains('- L5'));
      });
    });

    group('List marker normalization', () {
      test('normalizes * to -', () {
        final result = formatter.format('* item 1\n* item 2');
        expect(result, contains('- item 1'));
        expect(result, contains('- item 2'));
        expect(result, isNot(contains('* item')));
      });

      test('normalizes + to -', () {
        final result = formatter.format('+ item 1\n+ item 2');
        expect(result, contains('- item 1'));
        expect(result, contains('- item 2'));
      });
    });

    group('Table formatting', () {
      test('aligns table columns', () {
        final input = '''| a | b |
|---|---|
| 1 | 2 |
| 10 | 20 |''';
        final result = formatter.format(input);
        expect(result, contains('|'));
        expect(result, contains('---'));
      });

      test('handles table alignment markers', () {
        final input = '''| Left | Center | Right |
|:-----|:------:|------:|
| L | C | R |''';
        final result = formatter.format(input);
        expect(result, contains('Left'));
        expect(result, contains('Center'));
        expect(result, contains('Right'));
      });
    });

    group('Image formatting', () {
      test('preserves basic image syntax', () {
        final result = formatter.format('![alt text](image.png)');
        expect(result, contains('![alt text](image.png)'));
      });
    });

    group('Checkbox lists', () {
      test('preserves unchecked checkbox', () {
        final result = formatter.format('- [ ] task 1');
        expect(result, contains('[ ]'));
        expect(result, contains('task 1'));
      });

      test('preserves checked checkbox', () {
        final result = formatter.format('- [x] done task');
        expect(result, contains('[x]'));
        expect(result, contains('done task'));
      });
    });

    group('Horizontal rule normalization', () {
      test('normalizes *** to ---', () {
        final result = formatter.format('***');
        expect(result.trim(), '---');
      });

      test('normalizes ___ to ---', () {
        final result = formatter.format('___');
        expect(result.trim(), '---');
      });
    });
  });

  group('formatMarkdown convenience function', () {
    test('formats with default options', () {
      final result = formatMarkdown('# Test');
      expect(result.trim(), '# Test');
    });

    test('accepts custom options', () {
      final result = formatMarkdown(
        '*emphasis*',
        options: const FormatOptions(),
      );
      expect(result, contains('_emphasis_'));
    });
  });
}
