/// Internal tests for Markdown normalizer.
library;

import 'package:dapper/src/markdown/normalizer.dart';
import 'package:test/test.dart';

void main() {
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
