import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('Markdown List Style', () {
    test('uses dash bullets by default', () {
      const input = '- item 1\n- item 2';
      final formatter = MarkdownFormatter();
      expect(formatter.format(input), '- item 1\n- item 2\n');
    });

    test('uses asterisk bullets when configured', () {
      const input = '- item 1\n- item 2';
      final options = FormatOptions(ulStyle: UnorderedListStyle.asterisk);
      final formatter = MarkdownFormatter(options);
      expect(formatter.format(input), '* item 1\n* item 2\n');
    });

    test('uses plus bullets when configured', () {
      const input = '- item 1\n- item 2';
      final options = FormatOptions(ulStyle: UnorderedListStyle.plus);
      final formatter = MarkdownFormatter(options);
      expect(formatter.format(input), '+ item 1\n+ item 2\n');
    });

    test('converts existing bullets to configured style', () {
      const input = '* item 1\n* item 2';
      final options = FormatOptions(ulStyle: UnorderedListStyle.dash);
      final formatter = MarkdownFormatter(options);
      expect(formatter.format(input), '- item 1\n- item 2\n');
    });
  });
}
