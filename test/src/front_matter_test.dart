/// Internal tests for front matter parsing.
library;

import 'package:dapper/src/markdown/front_matter.dart';
import 'package:test/test.dart';

void main() {
  group('extractFrontMatter', () {
    test('extracts valid front matter', () {
      final input = '''---
title: My Document
author: John
---
# Content''';
      final result = extractFrontMatter(input);
      expect(result.hasFrontMatter, isTrue);
      expect(result.frontMatter, contains('title: My Document'));
      expect(result.frontMatter, contains('author: John'));
      expect(result.content.trim(), '# Content');
    });

    test('handles no front matter', () {
      final input = '# Just content';
      final result = extractFrontMatter(input);
      expect(result.hasFrontMatter, isFalse);
      expect(result.frontMatter, isNull);
      expect(result.content, input);
    });

    test('handles empty input', () {
      final result = extractFrontMatter('');
      expect(result.hasFrontMatter, isFalse);
      expect(result.content, '');
    });

    test('handles unclosed front matter', () {
      final input = '''---
title: Incomplete
# Content''';
      final result = extractFrontMatter(input);
      expect(result.hasFrontMatter, isFalse);
      expect(result.content, input);
    });

    test('handles front matter not at beginning', () {
      final input = '''Some text
---
title: Not front matter
---''';
      final result = extractFrontMatter(input);
      expect(result.hasFrontMatter, isFalse);
    });
  });

  group('withFrontMatter', () {
    test('reconstructs document with front matter', () {
      final result = withFrontMatter('title: Test', '# Content');
      expect(result, contains('---'));
      expect(result, contains('title: Test'));
      expect(result, contains('# Content'));
    });

    test('returns content only when front matter is null', () {
      final result = withFrontMatter(null, '# Content');
      expect(result, '# Content');
    });

    test('returns content only when front matter is empty', () {
      final result = withFrontMatter('', '# Content');
      expect(result, '# Content');
    });
  });
}
