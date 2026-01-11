/// Internal tests for text utilities.
library;

import 'package:dapper/src/utils/text_utils.dart';
import 'package:test/test.dart';

void main() {
  group('wrapText', () {
    test('wraps at word boundaries', () {
      final lines = wrapText('hello world foo bar', 10);
      expect(lines, ['hello', 'world foo', 'bar']);
    });

    test('handles empty string', () {
      expect(wrapText('', 80), ['']);
    });

    test('handles single word longer than width', () {
      final lines = wrapText('superlongword', 5);
      expect(lines, ['superlongword']);
    });

    test('handles multiple spaces', () {
      final lines = wrapText('hello    world', 20);
      expect(lines, ['hello world']);
    });
  });

  group('normalizeWhitespace', () {
    test('collapses spaces', () {
      expect(normalizeWhitespace('  hello   world  '), 'hello world');
    });

    test('handles tabs', () {
      expect(normalizeWhitespace('\thello\t\tworld\t'), 'hello world');
    });
  });

  group('ensureTrailingNewline', () {
    test('adds newline when missing', () {
      expect(ensureTrailingNewline('hello'), 'hello\n');
    });

    test('preserves single newline', () {
      expect(ensureTrailingNewline('hello\n'), 'hello\n');
    });

    test('normalizes multiple newlines', () {
      expect(ensureTrailingNewline('hello\n\n'), 'hello\n');
    });

    test('handles empty string', () {
      expect(ensureTrailingNewline(''), '');
    });
  });

  group('indent', () {
    test('creates space string', () {
      expect(indent(4), '    ');
    });

    test('returns empty for zero', () {
      expect(indent(0), '');
    });

    test('returns empty for negative', () {
      expect(indent(-1), '');
    });
  });

  group('displayWidth', () {
    test('returns string length', () {
      expect(displayWidth('hello'), 5);
    });
  });

  group('repeat', () {
    test('repeats string', () {
      expect(repeat('ab', 3), 'ababab');
    });

    test('returns empty for zero count', () {
      expect(repeat('ab', 0), '');
    });

    test('returns empty for negative count', () {
      expect(repeat('ab', -1), '');
    });
  });

  // Additional tests for 100% coverage

  group('wrapText edge cases', () {
    test('throws for zero width', () {
      expect(() => wrapText('text', 0), throwsArgumentError);
    });

    test('throws for negative width', () {
      expect(() => wrapText('text', -1), throwsArgumentError);
    });
  });

  group('trimTrailingWhitespace', () {
    test('removes trailing spaces from each line', () {
      expect(trimTrailingWhitespace('hello  \nworld  '), 'hello\nworld');
    });

    test('handles empty input', () {
      expect(trimTrailingWhitespace(''), '');
    });
  });

  group('indent with tabs', () {
    test('uses tabs when useTabs is true', () {
      expect(indent(4, useTabs: true, tabWidth: 2), '\t\t');
    });

    test('uses mixed tabs and spaces', () {
      expect(indent(5, useTabs: true, tabWidth: 2), '\t\t ');
    });

    test('uses only spaces for width less than tabWidth', () {
      expect(indent(1, useTabs: true, tabWidth: 2), ' ');
    });
  });
}
