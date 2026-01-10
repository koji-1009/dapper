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
}
