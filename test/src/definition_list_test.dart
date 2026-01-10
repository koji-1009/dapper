/// Internal tests for definition list parsing.
library;

import 'package:dapper/src/markdown/definition_list.dart';
import 'package:test/test.dart';

void main() {
  group('hasDefinitionLists', () {
    test('detects definition list syntax', () {
      expect(hasDefinitionLists('Term\n: Definition'), isTrue);
    });

    test('returns false for regular content', () {
      expect(hasDefinitionLists('# Just heading'), isFalse);
      expect(hasDefinitionLists('Regular paragraph'), isFalse);
    });

    test('handles empty input', () {
      expect(hasDefinitionLists(''), isFalse);
    });
  });

  group('parseDocumentSegments', () {
    test('parses single definition list', () {
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

    test('parses multiple definitions per term', () {
      final input = '''Term
: Def 1
: Def 2
: Def 3''';
      final segments = parseDocumentSegments(input);
      expect(segments.length, 1);
      final dlSegment = segments[0] as DefinitionListSegment;
      expect(dlSegment.definitionList.items[0].definitions.length, 3);
    });

    test('parses mixed content', () {
      final input = '''# Heading

Term
: Definition

Regular paragraph''';
      final segments = parseDocumentSegments(input);
      expect(segments.length, 3);
      expect(segments[0], isA<MarkdownSegment>());
      expect(segments[1], isA<DefinitionListSegment>());
      expect(segments[2], isA<MarkdownSegment>());
    });

    test('handles content without definition lists', () {
      final input = '''# Heading

Regular paragraph''';
      final segments = parseDocumentSegments(input);
      expect(segments.length, 1);
      expect(segments[0], isA<MarkdownSegment>());
    });
  });

  group('formatDefinitionList', () {
    test('formats single item', () {
      final list = DefinitionList([
        DefinitionItem('Term', ['Definition']),
      ]);
      final result = formatDefinitionList(list);
      expect(result, contains('Term'));
      expect(result, contains(': Definition'));
    });

    test('formats multiple items', () {
      final list = DefinitionList([
        DefinitionItem('Term 1', ['Def 1']),
        DefinitionItem('Term 2', ['Def 2a', 'Def 2b']),
      ]);
      final result = formatDefinitionList(list);
      expect(result, contains('Term 1'));
      expect(result, contains(': Def 1'));
      expect(result, contains('Term 2'));
      expect(result, contains(': Def 2a'));
      expect(result, contains(': Def 2b'));
    });
  });
}
