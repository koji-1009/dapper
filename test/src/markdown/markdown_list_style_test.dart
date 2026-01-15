import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('Markdown List Style', () {
    test('uses asterisk bullets by default', () {
      const input = '- item 1\n- item 2';
      const formatter = MarkdownFormatter();
      expect(formatter.format(input), '* item 1\n* item 2\n');
    });

    test('uses asterisk bullets when configured', () {
      const input = '- item 1\n- item 2';
      const options = FormatOptions(ulStyle: UnorderedListStyle.asterisk);
      const formatter = MarkdownFormatter(options);
      expect(formatter.format(input), '* item 1\n* item 2\n');
    });

    test('uses plus bullets when configured', () {
      const input = '- item 1\n- item 2';
      const options = FormatOptions(ulStyle: UnorderedListStyle.plus);
      const formatter = MarkdownFormatter(options);
      expect(formatter.format(input), '+ item 1\n+ item 2\n');
    });

    test('converts existing bullets to configured style', () {
      const input = '- item 1\n- item 2';
      const options = FormatOptions(ulStyle: UnorderedListStyle.dash);
      const formatter = MarkdownFormatter(options);
      expect(formatter.format(input), '- item 1\n- item 2\n');
    });
  });
}
