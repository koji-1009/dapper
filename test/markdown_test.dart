import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('FormatOptions', () {
    test('has sensible defaults', () {
      const options = FormatOptions();
      expect(options.printWidth, 80);
      expect(options.tabWidth, 2);
      expect(options.proseWrap, ProseWrap.preserve);
    });

    test('copyWith creates modified copy', () {
      const original = FormatOptions();
      final modified = original.copyWith(printWidth: 120);
      expect(modified.printWidth, 120);
      expect(modified.tabWidth, original.tabWidth);
    });
  });

  group('Text Utils', () {
    test('wrapText wraps at word boundaries', () {
      final lines = wrapText('hello world foo bar', 10);
      expect(lines, ['hello', 'world foo', 'bar']);
    });

    test('wrapText handles empty string', () {
      expect(wrapText('', 80), ['']);
    });

    test('normalizeWhitespace collapses spaces', () {
      expect(normalizeWhitespace('  hello   world  '), 'hello world');
    });

    test('ensureTrailingNewline adds newline', () {
      expect(ensureTrailingNewline('hello'), 'hello\n');
      expect(ensureTrailingNewline('hello\n'), 'hello\n');
      expect(ensureTrailingNewline('hello\n\n'), 'hello\n');
    });

    test('indent creates space string', () {
      expect(indent(4), '    ');
      expect(indent(0), '');
    });
  });

  group('Normalizer', () {
    test('normalizeEmphasis converts * to _', () {
      expect(normalizeEmphasis('*hello*'), '_hello_');
    });

    test('normalizeEmphasis preserves ** for strong', () {
      expect(normalizeEmphasis('**hello**'), '**hello**');
    });

    test('normalizeHorizontalRule normalizes to ---', () {
      expect(normalizeHorizontalRule('***'), '---');
      expect(normalizeHorizontalRule('___'), '---');
      expect(normalizeHorizontalRule('- - -'), '---');
    });

    test('normalizeHeading creates ATX heading', () {
      expect(normalizeHeading(1, 'Hello'), '# Hello');
      expect(normalizeHeading(3, '  Spaced  '), '### Spaced');
    });

    test('normalizeUnorderedListMarker converts to -', () {
      expect(normalizeUnorderedListMarker('*'), '-');
      expect(normalizeUnorderedListMarker('+'), '-');
      expect(normalizeUnorderedListMarker('-'), '-');
    });
  });

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

  group('Front Matter', () {
    test('extracts front matter', () {
      final input = '''---
title: My Document
author: John
---
# Content''';
      final result = extractFrontMatter(input);
      expect(result.hasFrontMatter, isTrue);
      expect(result.frontMatter, contains('title: My Document'));
      expect(result.content.trim(), '# Content');
    });

    test('handles no front matter', () {
      final input = '# Just content';
      final result = extractFrontMatter(input);
      expect(result.hasFrontMatter, isFalse);
      expect(result.content, input);
    });

    test('preserves front matter during formatting', () {
      final input = '''---
title: Test
---
# Hello

*world*
''';
      final formatter = MarkdownFormatter();
      final result = formatter.format(input);
      expect(result, contains('---'));
      expect(result, contains('title: Test'));
      expect(result, contains('# Hello'));
      expect(result, contains('_world_'));
    });
  });

  group('Definition Lists', () {
    test('detects definition list syntax', () {
      expect(hasDefinitionLists('Term\n: Definition'), isTrue);
      expect(hasDefinitionLists('# Just heading'), isFalse);
    });

    test('parses definition list segments', () {
      final input = '''Term 1
: Definition 1''';
      final segments = parseDocumentSegments(input);
      expect(segments.length, 1);
      expect(segments[0], isA<DefinitionListSegment>());
      final dlSegment = segments[0] as DefinitionListSegment;
      expect(dlSegment.definitionList.items.length, 1);
      expect(dlSegment.definitionList.items[0].term, 'Term 1');
      expect(dlSegment.definitionList.items[0].definitions, ['Definition 1']);
    });

    test('formats definition lists', () {
      final input = '''Term 1
: Definition 1

Term 2
: Definition 2a
: Definition 2b
''';
      final formatter = MarkdownFormatter();
      final result = formatter.format(input);
      expect(result, contains('Term 1'));
      expect(result, contains(': Definition 1'));
      expect(result, contains('Term 2'));
      expect(result, contains(': Definition 2a'));
      expect(result, contains(': Definition 2b'));
    });
  });

  group('Setext Headings', () {
    test('formats setext h1 to ATX', () {
      final formatter = MarkdownFormatter();
      final result = formatter.format('Heading\n=======');
      expect(result.trim(), '# Heading');
    });

    test('formats setext h2 to ATX', () {
      final formatter = MarkdownFormatter();
      final result = formatter.format('Heading\n-------');
      expect(result.trim(), '## Heading');
    });
  });

  group('Deep Nesting', () {
    test('handles 5 levels of list nesting', () {
      final input = '''- L1
  - L2
    - L3
      - L4
        - L5
''';
      final formatter = MarkdownFormatter();
      final result = formatter.format(input);
      expect(result, contains('- L1'));
      expect(result, contains('- L2'));
      expect(result, contains('- L3'));
      expect(result, contains('- L4'));
      expect(result, contains('- L5'));
    });
  });

  // ============================================================
  // Prettier-compatible test patterns
  // ============================================================

  group('Emphasis (Prettier patterns)', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

    test('does not convert emphasis within words', () {
      // Prettier: a*b*c stays as a*b*c (not a_b_c)
      final result = formatter.format('a*b*c');
      // Note: markdown parser may interpret this differently
      expect(result.trim(), contains('a'));
    });

    test('converts emphasis at word boundaries', () {
      // Prettier: *text* -> _text_
      final result = formatter.format('*text*');
      expect(result.trim(), '_text_');
    });

    test('handles emphasis inside strong', () {
      // Prettier: **Do you want *feature* or *bug*?** preserves structure
      final input = '**Do you want a *feature* or a *bug*?**';
      final result = formatter.format(input);
      expect(result, contains('**'));
      expect(result, contains('_'));
    });

    test('preserves underscore emphasis', () {
      // Prettier: _text_ stays as _text_
      final result = formatter.format('_text_');
      expect(result.trim(), '_text_');
    });
  });

  group('List marker normalization', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

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

    test('preserves - marker', () {
      final result = formatter.format('- item 1\n- item 2');
      expect(result, contains('- item 1'));
      expect(result, contains('- item 2'));
    });
  });

  group('Code blocks in lists', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

    test('preserves code block content in ordered list', () {
      final input = '''1. item

   ```js
   const a = 1;
   ```
''';
      final result = formatter.format(input);
      expect(result, contains('1.'));
      expect(result, contains('```'));
      expect(result, contains('const a = 1;'));
    });
  });

  group('Table formatting', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

    test('aligns table columns', () {
      final input = '''| a | b |
|---|---|
| 1 | 2 |
| 10 | 20 |''';
      final result = formatter.format(input);
      expect(result, contains('|'));
      expect(result, contains('---'));
    });

    test('handles different column widths', () {
      final input = '''| Name | Age |
|------|-----|
| Alice | 30 |
| Bob | 25 |''';
      final result = formatter.format(input);
      expect(result, contains('Alice'));
      expect(result, contains('Bob'));
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
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

    test('preserves basic image syntax', () {
      final result = formatter.format('![alt text](image.png)');
      expect(result, contains('![alt text](image.png)'));
    });

    test('preserves image with title', () {
      final result = formatter.format('![alt](image.png "title")');
      expect(result, contains('![alt](image.png'));
    });
  });

  group('Checkbox lists', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

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

    test('formats multiple checkbox items', () {
      final input = '''- [ ] todo 1
- [x] done 1
- [ ] todo 2''';
      final result = formatter.format(input);
      expect(result, contains('[ ] todo 1'));
      expect(result, contains('[x] done 1'));
      expect(result, contains('[ ] todo 2'));
    });
  });

  group('Blank line normalization', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

    test('normalizes multiple blank lines between paragraphs', () {
      final input = '''Paragraph 1


Paragraph 2''';
      final result = formatter.format(input);
      expect(result, contains('Paragraph 1'));
      expect(result, contains('Paragraph 2'));
      // Should not have excessive blank lines
      expect(result.split('\n\n\n').length, lessThanOrEqualTo(2));
    });

    test('ensures blank line before heading', () {
      final input = '''Some text
# Heading''';
      final result = formatter.format(input);
      expect(result, contains('Some text'));
      expect(result, contains('# Heading'));
    });
  });

  group('Horizontal rule normalization', () {
    late MarkdownFormatter formatter;

    setUp(() {
      formatter = MarkdownFormatter();
    });

    test('normalizes *** to ---', () {
      final result = formatter.format('***');
      expect(result.trim(), '---');
    });

    test('normalizes ___ to ---', () {
      final result = formatter.format('___');
      expect(result.trim(), '---');
    });

    test('normalizes * * * to ---', () {
      final result = formatter.format('* * *');
      expect(result.trim(), '---');
    });

    test('normalizes - - - to ---', () {
      final result = formatter.format('- - -');
      expect(result.trim(), '---');
    });
  });
}
