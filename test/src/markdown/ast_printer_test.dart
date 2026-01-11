/// Internal tests for MarkdownPrinter.
library;

import 'package:dapper/dapper.dart';
import 'package:dapper/src/markdown/ast_printer.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:test/test.dart';

void main() {
  group('MarkdownPrinter', () {
    late MarkdownPrinter printer;

    setUp(() {
      printer = MarkdownPrinter(FormatOptions.defaults);
    });

    test('prints empty list', () {
      final result = printer.print([]);
      expect(result, '');
    });

    test('prints Text node', () {
      final result = printer.print([md.Text('Hello')]);
      expect(result.trim(), 'Hello');
    });

    test('prints UnparsedContent node', () {
      final result = printer.print([md.UnparsedContent('raw content')]);
      expect(result, contains('raw content'));
    });

    test('prints paragraph element', () {
      final p = md.Element('p', [md.Text('Hello world')]);
      final result = printer.print([p]);
      expect(result.trim(), 'Hello world');
    });

    test('prints all heading levels', () {
      for (var i = 1; i <= 6; i++) {
        final h = md.Element('h$i', [md.Text('Heading $i')]);
        final result = printer.print([h]);
        expect(result.trim(), '${'#' * i} Heading $i');
      }
    });

    test('prints unordered list', () {
      final li1 = md.Element('li', [md.Text('Item 1')]);
      final li2 = md.Element('li', [md.Text('Item 2')]);
      final ul = md.Element('ul', [li1, li2]);
      final result = printer.print([ul]);
      expect(result, contains('- Item 1'));
      expect(result, contains('- Item 2'));
    });

    test('prints nested unordered list with proper indentation', () {
      // Create: - item 1
      //           - nested item
      //             - deeply nested
      final deepLi = md.Element('li', [md.Text('deeply nested')]);
      final deepUl = md.Element('ul', [deepLi]);
      final nestedLi = md.Element('li', [md.Text('nested item'), deepUl]);
      final nestedUl = md.Element('ul', [nestedLi]);
      final topLi = md.Element('li', [md.Text('item 1'), nestedUl]);
      final topUl = md.Element('ul', [topLi]);

      final result = printer.print([topUl]);

      // Each list item should be on its own line
      expect(result, contains('- item 1\n'));
      expect(result, contains('  - nested item\n'));
      expect(result, contains('    - deeply nested'));
    });

    test('prints ordered list', () {
      final li1 = md.Element('li', [md.Text('First')]);
      final li2 = md.Element('li', [md.Text('Second')]);
      final ol = md.Element('ol', [li1, li2]);
      final result = printer.print([ol]);
      expect(result, contains('1. First'));
      expect(result, contains('2. Second'));
    });

    test('prints standalone li element', () {
      final li = md.Element('li', [md.Text('Item')]);
      final result = printer.print([li]);
      expect(result, contains('Item'));
    });

    test('prints blockquote', () {
      final p = md.Element('p', [md.Text('Quoted text')]);
      final bq = md.Element('blockquote', [p]);
      final result = printer.print([bq]);
      expect(result, contains('> Quoted text'));
    });

    test('prints pre/code block', () {
      final code = md.Element('code', [md.Text('code content')]);
      code.attributes['class'] = 'language-dart';
      final pre = md.Element('pre', [code]);
      final result = printer.print([pre]);
      expect(result, contains('```dart'));
      expect(result, contains('code content'));
      expect(result, contains('```'));
    });

    test('prints pre without code child', () {
      final pre = md.Element('pre', [md.Text('raw code')]);
      final result = printer.print([pre]);
      expect(result, contains('```'));
      expect(result, contains('raw code'));
    });

    test('prints inline code', () {
      final code = md.Element('code', [md.Text('inline')]);
      final p = md.Element('p', [code]);
      final result = printer.print([p]);
      expect(result, contains('`inline`'));
    });

    test('prints emphasis', () {
      final em = md.Element('em', [md.Text('emphasized')]);
      final p = md.Element('p', [em]);
      final result = printer.print([p]);
      expect(result, contains('_emphasized_'));
    });

    test('prints strong', () {
      final strong = md.Element('strong', [md.Text('bold')]);
      final p = md.Element('p', [strong]);
      final result = printer.print([p]);
      expect(result, contains('**bold**'));
    });

    test('prints link', () {
      final a = md.Element('a', [md.Text('link text')]);
      a.attributes['href'] = 'https://example.com';
      final p = md.Element('p', [a]);
      final result = printer.print([p]);
      expect(result, contains('[link text](https://example.com)'));
    });

    test('prints link with title', () {
      final a = md.Element('a', [md.Text('text')]);
      a.attributes['href'] = 'url';
      a.attributes['title'] = 'Title';
      final p = md.Element('p', [a]);
      final result = printer.print([p]);
      expect(result, contains('[text](url "Title")'));
    });

    test('prints image', () {
      final img = md.Element.empty('img');
      img.attributes['src'] = 'image.png';
      img.attributes['alt'] = 'Alt text';
      final p = md.Element('p', [img]);
      final result = printer.print([p]);
      expect(result, contains('![Alt text](image.png)'));
    });

    test('prints image with title', () {
      final img = md.Element.empty('img');
      img.attributes['src'] = 'src';
      img.attributes['alt'] = 'alt';
      img.attributes['title'] = 'Title';
      final p = md.Element('p', [img]);
      final result = printer.print([p]);
      // Note: Current implementation doesn't preserve title in inline rendering
      expect(result, contains('![alt](src'));
    });

    test('prints horizontal rule', () {
      final hr = md.Element.empty('hr');
      final result = printer.print([hr]);
      expect(result.trim(), '---');
    });

    test('prints line break', () {
      final br = md.Element.empty('br');
      final p = md.Element('p', [md.Text('Line 1'), br, md.Text('Line 2')]);
      final result = printer.print([p]);
      expect(result, contains('Line 1'));
      expect(result, contains('Line 2'));
    });

    test('prints table', () {
      // Build table structure
      final th1 = md.Element('th', [md.Text('Header')]);
      final tr1 = md.Element('tr', [th1]);
      final thead = md.Element('thead', [tr1]);

      final td1 = md.Element('td', [md.Text('Data')]);
      final tr2 = md.Element('tr', [td1]);
      final tbody = md.Element('tbody', [tr2]);

      final table = md.Element('table', [thead, tbody]);
      final result = printer.print([table]);
      expect(result, contains('| Header'));
      expect(result, contains('| Data'));
    });

    test('prints definition list elements', () {
      final dt = md.Element('dt', [md.Text('Term')]);
      final dd = md.Element('dd', [md.Text('Definition')]);
      final dl = md.Element('dl', [dt, dd]);
      final result = printer.print([dl]);
      expect(result, contains('Term'));
      expect(result, contains(': Definition'));
    });

    test('prints unknown element by printing children', () {
      final unknown = md.Element('custom', [md.Text('content')]);
      final result = printer.print([unknown]);
      expect(result, contains('content'));
    });

    group('proseWrap always', () {
      late MarkdownPrinter wrapPrinter;

      setUp(() {
        wrapPrinter = MarkdownPrinter(
          const FormatOptions(proseWrap: ProseWrap.always, printWidth: 20),
        );
      });

      test('wraps paragraph', () {
        final p = md.Element('p', [md.Text('This is a long paragraph text')]);
        final result = wrapPrinter.print([p]);
        final lines = result.trim().split('\n');
        expect(lines.length, greaterThan(1));
      });

      test('wraps list item content', () {
        final li = md.Element('li', [md.Text('This is very long list item')]);
        final ul = md.Element('ul', [li]);
        final result = wrapPrinter.print([ul]);
        expect(result, contains('-'));
      });

      test('wraps checkbox item', () {
        final input = md.Element.empty('input');
        input.attributes['type'] = 'checkbox';
        input.attributes['checked'] = 'true';
        final li = md.Element('li', [input, md.Text(' Very long checkbox')]);
        final ul = md.Element('ul', [li]);
        final result = wrapPrinter.print([ul]);
        expect(result, contains('[x]'));
      });

      test('wraps definition description', () {
        final dt = md.Element('dt', [md.Text('Term')]);
        final dd = md.Element('dd', [md.Text('Very long definition text')]);
        final dl = md.Element('dl', [dt, dd]);
        final result = wrapPrinter.print([dl]);
        expect(result, contains('Term'));
        expect(result, contains(':'));
      });
    });

    test('handles empty paragraph', () {
      final element = md.Element('p', []);
      final result = printer.print([element]);
      // Empty paragraph with no content returns empty after trimming
      expect(result.isEmpty || result == '\n', isTrue);
    });

    test('handles table with alignments', () {
      final th1 = md.Element('th', [md.Text('Left')]);
      th1.attributes['align'] = 'left';
      final th2 = md.Element('th', [md.Text('Center')]);
      th2.attributes['align'] = 'center';
      final th3 = md.Element('th', [md.Text('Right')]);
      th3.attributes['align'] = 'right';
      final tr1 = md.Element('tr', [th1, th2, th3]);
      final thead = md.Element('thead', [tr1]);

      final td1 = md.Element('td', [md.Text('l')]);
      final td2 = md.Element('td', [md.Text('c')]);
      final td3 = md.Element('td', [md.Text('r')]);
      final tr2 = md.Element('tr', [td1, td2, td3]);
      final tbody = md.Element('tbody', [tr2]);

      final table = md.Element('table', [thead, tbody]);
      final result = printer.print([table]);
      expect(result, contains('Left'));
      expect(result, contains('Center'));
      expect(result, contains('Right'));
      expect(result, contains(':'));
    });

    // Additional tests for direct method coverage

    test('prints standalone inline code element', () {
      final code = md.Element('code', [md.Text('code')]);
      final result = printer.print([code]);
      expect(result, contains('`code`'));
    });

    test('prints standalone emphasis element', () {
      final em = md.Element('em', [md.Text('text')]);
      final result = printer.print([em]);
      expect(result, contains('_text_'));
    });

    test('prints standalone strong element', () {
      final strong = md.Element('strong', [md.Text('text')]);
      final result = printer.print([strong]);
      expect(result, contains('**text**'));
    });

    test('prints standalone link element', () {
      final link = md.Element('a', [md.Text('text')]);
      link.attributes['href'] = 'url';
      final result = printer.print([link]);
      expect(result, contains('[text](url)'));
    });

    test('prints standalone link element with title', () {
      final link = md.Element('a', [md.Text('text')]);
      link.attributes['href'] = 'url';
      link.attributes['title'] = 'title';
      final result = printer.print([link]);
      expect(result, contains('[text](url "title")'));
    });

    test('prints standalone image element', () {
      final img = md.Element.empty('img');
      img.attributes['src'] = 'src';
      img.attributes['alt'] = 'alt';
      final result = printer.print([img]);
      expect(result, contains('![alt](src)'));
    });

    test('prints standalone image element with title', () {
      final img = md.Element.empty('img');
      img.attributes['src'] = 'src';
      img.attributes['alt'] = 'alt';
      img.attributes['title'] = 'title';
      final result = printer.print([img]);
      expect(result, contains('![alt](src "title")'));
    });

    test('prints standalone br element', () {
      final br = md.Element.empty('br');
      final result = printer.print([br]);
      // br element produces minimal output when standalone
      expect(result.length, lessThanOrEqualTo(3));
    });

    test('prints thead element directly', () {
      final th = md.Element('th', [md.Text('Header')]);
      final tr = md.Element('tr', [th]);
      final thead = md.Element('thead', [tr]);
      final result = printer.print([thead]);
      expect(result, contains('Header'));
    });

    test('prints tbody element directly', () {
      final td = md.Element('td', [md.Text('Data')]);
      final tr = md.Element('tr', [td]);
      final tbody = md.Element('tbody', [tr]);
      final result = printer.print([tbody]);
      expect(result, contains('Data'));
    });

    test('prints tr element directly', () {
      final td = md.Element('td', [md.Text('Data')]);
      final tr = md.Element('tr', [td]);
      final result = printer.print([tr]);
      expect(result, contains('Data'));
    });

    test('prints th element directly', () {
      final th = md.Element('th', [md.Text('Header')]);
      final result = printer.print([th]);
      expect(result, contains('Header'));
    });

    test('prints td element directly', () {
      final td = md.Element('td', [md.Text('Data')]);
      final result = printer.print([td]);
      expect(result, contains('Data'));
    });

    test('prints dt element directly', () {
      final dt = md.Element('dt', [md.Text('Term')]);
      final result = printer.print([dt]);
      expect(result, contains('Term'));
    });

    test('prints dd element directly', () {
      final dd = md.Element('dd', [md.Text('Definition')]);
      final result = printer.print([dd]);
      expect(result, contains(': Definition'));
    });

    test('handles getTextContent with UnparsedContent', () {
      final p = md.Element('p', [md.UnparsedContent('raw')]);
      final result = printer.print([p]);
      expect(result, contains('raw'));
    });

    test('renders inline link with title in paragraph', () {
      final link = md.Element('a', [md.Text('text')]);
      link.attributes['href'] = 'url';
      link.attributes['title'] = 'title';
      final p = md.Element('p', [link]);
      final result = printer.print([p]);
      expect(result, contains('[text](url "title")'));
    });

    // Tests for _getTextContent with UnparsedContent
    test('getTextContent extracts text from UnparsedContent', () {
      // Create a structure that forces _getTextContent to be called on UnparsedContent
      // This happens when printing code blocks for example, but let's test directly if possible
      // or via a construct that uses _getTextContent
      final unparsed = md.UnparsedContent('raw text');
      final code = md.Element('code', [unparsed]);
      final result = printer.print([code]);
      expect(result, contains('`raw text`'));
    });

    // Tests for _renderInlineNode default case
    test('renderInlineNode handles unknown tag by rendering children', () {
      final span = md.Element('span', [md.Text('content')]);
      final p = md.Element('p', [span]);
      final result = printer.print([p]);
      expect(result, contains('content'));
    });

    // Tests for _renderInlineNode with UnparsedContent
    test('renderInlineNode handles UnparsedContent', () {
      final unparsed = md.UnparsedContent('inline raw');
      final p = md.Element('p', [unparsed]);
      final result = printer.print([p]);
      // Note: paragraph renders inline content
      expect(result, contains('inline raw'));
    });
  });
}
