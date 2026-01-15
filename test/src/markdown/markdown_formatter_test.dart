/// Tests for MarkdownFormatter public API.
library;

import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownFormatter', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = const MarkdownFormatter();
    });

    test('formats empty string', () {
      expect(formatter.format(''), '');
    });

    test('formats heading', () {
      final result = formatter.format('# Hello World');
      expect(result.trim(), '# Hello World');
    });

    test('formats heading with inline code', () {
      final result = formatter.format('## `Markdown`');
      expect(result.trim(), '## `Markdown`');
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
      expect(result, contains('* item 1'));
      expect(result, contains('* item 2'));
    });

    test('formats ordered list', () {
      final result = formatter.format('1. first\n2. second');
      expect(result, contains('1. first'));
      expect(result, contains('2. second'));
    });

    test('formats code block', () {
      const input = '''
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
        formatter = const MarkdownFormatter(
          FormatOptions(proseWrap: ProseWrap.always, printWidth: 40),
        );
      });

      test('wraps long paragraphs', () {
        const input =
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
        const input = '''---
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
        const input = '''Term 1
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
        const input = '''- L1
  - L2
    - L3
      - L4
        - L5
''';
        final result = formatter.format(input);
        expect(result, contains('* L1'));
        expect(result, contains('* L2'));
        expect(result, contains('* L3'));
        expect(result, contains('* L4'));
        expect(result, contains('* L5'));
      });

      test('does not insert extra blank lines between nested list items', () {
        const input = '''- [clock](https://pub.dev/packages/clock)
  - Get current time and mock time
- [crypto](https://pub.dev/packages/crypto)
  - Get persistent file name from URL and options
- [image](https://pub.dev/packages/image)
  - Resize image
''';
        final result = formatter.format(input);
        // Should not have blank lines between parent and child list items
        expect(result, isNot(contains('clock)\n\n  *')));
        expect(result, isNot(contains('crypto)\n\n  *')));
        expect(result, isNot(contains('image)\n\n  *')));
        // Verify the nested structure is preserved
        expect(result, contains('* [clock]'));
        expect(result, contains('  * Get current time'));
        expect(result, contains('* [crypto]'));
        expect(result, contains('  * Get persistent file name'));
      });

      test('preserves nested list structure with mixed content', () {
        const input = '''- Parent 1
  - Child 1a
  - Child 1b
- Parent 2
  - Child 2a
''';
        final result = formatter.format(input);
        // Check no extra blank lines
        final lines = result.split('\n');
        final nonEmptyLines = lines.where((l) => l.trim().isNotEmpty).toList();
        expect(nonEmptyLines.length, 5);
      });
    });

    group('List marker normalization', () {
      test('normalizes - to *', () {
        final result = formatter.format('- item 1\n- item 2');
        expect(result, contains('* item 1'));
        expect(result, contains('* item 2'));
        expect(result, isNot(contains('- item')));
      });

      test('normalizes + to *', () {
        final result = formatter.format('+ item 1\n+ item 2');
        expect(result, contains('* item 1'));
        expect(result, contains('* item 2'));
      });

      test('normalizes spaces in list items', () {
        const input = '''
*   Item 1
*    Item 2
''';
        final result = formatter.format(input);
        expect(result, contains('* Item 1'));
        expect(result, contains('* Item 2'));
        expect(result, isNot(contains('*   Item 1')));
      });

      test('normalizes spaces in headings', () {
        final result = formatter.format('#    Heading');
        expect(result.trim(), '# Heading');
      });

      test('normalizes spaces in blockquotes', () {
        final result = formatter.format('>    Blockquote');
        expect(result.trim(), '> Blockquote');
      });
    });

    group('Table formatting', () {
      test('aligns table columns', () {
        const input = '''| a | b |
|---|---|
| 1 | 2 |
| 10 | 20 |''';
        final result = formatter.format(input);
        expect(result, contains('|'));
        expect(result, contains('---'));
      });

      test('handles table alignment markers', () {
        const input = '''| Left | Center | Right |
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

  // Additional tests for 100% coverage
  group('Additional coverage tests', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = const MarkdownFormatter();
    });

    group('proseWrap always', () {
      late MarkdownFormatter wrapFormatter;

      setUp(() {
        wrapFormatter = const MarkdownFormatter(
          FormatOptions(proseWrap: ProseWrap.always, printWidth: 30),
        );
      });

      test('wraps long checkbox items', () {
        final result = wrapFormatter.format(
          '- [ ] This is a very long checkbox item that should wrap',
        );
        expect(result, contains('[ ]'));
        expect(result, contains('checkbox'));
      });

      test('wraps long blockquotes', () {
        final result = wrapFormatter.format(
          '> This is a very long blockquote that should wrap at the specified width',
        );
        expect(result, contains('>'));
      });

      test('wraps long list items', () {
        final result = wrapFormatter.format(
          '- This is a very long list item that should wrap at the width',
        );
        expect(result, contains('*'));
      });

      test('wraps definition descriptions', () {
        final result = wrapFormatter.format(
          'Term\n: This is a very long definition that should wrap nicely',
        );
        expect(result, contains('Term'));
        expect(result, contains(':'));
      });
    });

    group('All heading levels', () {
      test('formats h1 through h6', () {
        expect(formatter.format('# H1').trim(), '# H1');
        expect(formatter.format('## H2').trim(), '## H2');
        expect(formatter.format('### H3').trim(), '### H3');
        expect(formatter.format('#### H4').trim(), '#### H4');
        expect(formatter.format('##### H5').trim(), '##### H5');
        expect(formatter.format('###### H6').trim(), '###### H6');
      });
    });

    group('Links with titles', () {
      test('formats link with title', () {
        final result = formatter.format('[text](url "title")');
        expect(result, contains('[text]'));
        expect(result, contains('url'));
      });
    });

    group('Images', () {
      test('formats image with title', () {
        final result = formatter.format('![alt](src "title")');
        expect(result, contains('![alt]'));
        expect(result, contains('src'));
      });
    });

    group('Line breaks', () {
      test('formats hard line breaks', () {
        final result = formatter.format('Line 1  \nLine 2');
        expect(result, contains('Line 1'));
        expect(result, contains('Line 2'));
      });
    });

    group('Tables', () {
      test('formats table with center alignment', () {
        const input = '''| Center |
|:------:|
| data |''';
        final result = formatter.format(input);
        expect(result, contains('Center'));
        expect(result, contains(':'));
      });

      test('formats table with right alignment', () {
        const input = '''| Right |
|------:|
| data |''';
        final result = formatter.format(input);
        expect(result, contains('Right'));
      });

      test('formats table with left alignment', () {
        const input = '''| Left |
|:------|
| data |''';
        final result = formatter.format(input);
        expect(result, contains('Left'));
      });

      test('formats empty table', () {
        final result = formatter.format('| |\n|-|');
        expect(result, contains('|'));
      });

      test('handles table with multiple columns', () {
        const input = '''| A | B | C |
|---|---|---|
| 1 | 2 | 3 |''';
        final result = formatter.format(input);
        expect(result, contains('A'));
        expect(result, contains('B'));
        expect(result, contains('C'));
      });
    });

    group('Complex list items', () {
      test('handles list with nested paragraphs', () {
        const input = '''- Item 1

  Continued paragraph

- Item 2''';
        final result = formatter.format(input);
        expect(result, contains('Item 1'));
        expect(result, contains('Item 2'));
      });

      test('handles ordered list with many items', () {
        const input = '''1. One
2. Two
3. Three
4. Four
5. Five
6. Six
7. Seven
8. Eight
9. Nine
10. Ten''';
        final result = formatter.format(input);
        expect(result, contains('10.'));
      });
    });

    group('Code blocks', () {
      test('formats code block without language', () {
        const input = '''```
code here
```''';
        final result = formatter.format(input);
        expect(result, contains('```'));
        expect(result, contains('code here'));
      });

      test('formats code block with trailing newline', () {
        const input = '''```js
code
```''';
        final result = formatter.format(input);
        expect(result, contains('```js'));
      });
    });

    group('Nested formatting', () {
      test('handles strong inside emphasis', () {
        final result = formatter.format('_**nested**_');
        expect(result, contains('_'));
        expect(result, contains('**'));
      });

      test('handles emphasis inside strong', () {
        final result = formatter.format('**_nested_**');
        expect(result, contains('**'));
        expect(result, contains('_'));
      });

      test('handles code inside link', () {
        final result = formatter.format('[`code`](url)');
        expect(result, contains('`code`'));
        expect(result, contains('url'));
      });
    });

    group('proseWrap never', () {
      test('never wraps long paragraphs', () {
        const neverFormatter = MarkdownFormatter(
          FormatOptions(proseWrap: ProseWrap.never, printWidth: 10),
        );
        final result = neverFormatter.format('This is a very long line');
        expect(result.trim(), 'This is a very long line');
      });
    });

    group('Definition list with markdown', () {
      test('formats markdown followed by definition list', () {
        const input = '''# Heading

Some paragraph text.

Term
: Definition
''';
        final result = formatter.format(input);
        expect(result, contains('# Heading'));
        expect(result, contains('Some paragraph text'));
        expect(result, contains('Term'));
        expect(result, contains(': Definition'));
      });

      test('formats definition list followed by markdown', () {
        const input = '''Term
: Definition

# Next Section
''';
        final result = formatter.format(input);
        expect(result, contains('Term'));
        expect(result, contains(': Definition'));
        expect(result, contains('# Next Section'));
      });

      test('formats markdown between definition lists', () {
        const input = '''Term1
: Def1

Paragraph between.

Term2
: Def2
''';
        final result = formatter.format(input);
        expect(result, contains('Term1'));
        expect(result, contains('Paragraph between'));
        expect(result, contains('Term2'));
      });
    });
  });
}
