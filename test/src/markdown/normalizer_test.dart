/// Internal tests for Markdown normalizer.
library;

import 'package:dapper/src/markdown/normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeEmphasis', () {
    test('converts * to _', () {
      expect(normalizeEmphasis('*hello*'), '_hello_');
    });

    test('preserves ** for strong', () {
      expect(normalizeEmphasis('**hello**'), '**hello**');
    });

    test('handles mixed emphasis', () {
      expect(normalizeEmphasis('***hello***'), '**_hello_**');
    });
  });

  group('normalizeHorizontalRule', () {
    test('normalizes *** to ---', () {
      expect(normalizeHorizontalRule('***'), '---');
    });

    test('normalizes ___ to ---', () {
      expect(normalizeHorizontalRule('___'), '---');
    });

    test('normalizes spaced markers', () {
      expect(normalizeHorizontalRule('- - -'), '---');
      expect(normalizeHorizontalRule('* * *'), '---');
    });
  });

  group('normalizeHeading', () {
    test('creates ATX heading level 1', () {
      expect(normalizeHeading(1, 'Hello'), '# Hello');
    });

    test('creates ATX heading level 3', () {
      expect(normalizeHeading(3, 'Title'), '### Title');
    });

    test('trims content', () {
      expect(normalizeHeading(1, '  Spaced  '), '# Spaced');
    });
  });

  group('normalizeUnorderedListMarker', () {
    test('converts * to -', () {
      expect(normalizeUnorderedListMarker('*'), '-');
    });

    test('converts + to -', () {
      expect(normalizeUnorderedListMarker('+'), '-');
    });

    test('preserves -', () {
      expect(normalizeUnorderedListMarker('-'), '-');
    });
  });

  // Additional tests for 100% coverage

  group('normalizeEmphasis edge cases', () {
    test('does not convert emphasis with leading space', () {
      // * text* should not be converted (space after first *)
      final result = normalizeEmphasis('* text*');
      expect(result, '* text*');
    });

    test('does not convert emphasis with trailing space', () {
      // *text * should not be converted (space before closing *)
      final result = normalizeEmphasis('*text *');
      expect(result, '*text *');
    });

    test('handles emphasis inside words', () {
      // a*b*c should stay as a*b*c
      final result = normalizeEmphasis('a*b*c');
      expect(result, 'a*b*c');
    });
  });

  group('orderedListContentIndent', () {
    test('calculates indent for single digit numbers', () {
      expect(orderedListContentIndent(9, 2), 3); // 1 + 2
    });

    test('calculates indent for double digit numbers', () {
      expect(orderedListContentIndent(99, 2), 4); // 2 + 2
    });

    test('calculates indent for triple digit numbers', () {
      expect(orderedListContentIndent(999, 2), 5); // 3 + 2
    });
  });

  group('normalizeCodeFence', () {
    test('converts tilde fence to backticks', () {
      expect(normalizeCodeFence('~~~'), '```');
    });

    test('converts longer tilde fence to backticks', () {
      expect(normalizeCodeFence('~~~~'), '````');
    });

    test('preserves backtick fence', () {
      expect(normalizeCodeFence('```'), '```');
    });
  });

  group('normalizeHeading edge cases', () {
    test('handles level less than 1', () {
      expect(normalizeHeading(0, 'Text'), '# Text');
    });

    test('handles level greater than 6', () {
      expect(normalizeHeading(7, 'Text'), '###### Text');
    });

    test('handles empty content', () {
      expect(normalizeHeading(1, ''), '#');
    });

    test('handles whitespace-only content', () {
      expect(normalizeHeading(1, '   '), '#');
    });
  });
}
