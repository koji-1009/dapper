/// Markdown AST printer.
///
/// Converts a markdown AST back to formatted markdown text.
library;

import 'package:markdown/markdown.dart' as md;

import '../options.dart';
import '../utils/text_utils.dart';
import 'normalizer.dart';

/// Prints a markdown AST node to formatted string.
class MarkdownPrinter {
  final FormatOptions options;
  final StringBuffer _buffer = StringBuffer();
  int _currentIndent = 0;
  bool _needsBlankLine = false;
  int _listDepth = 0;

  MarkdownPrinter(this.options);

  /// Prints the given nodes and returns the formatted string.
  String print(List<md.Node> nodes) {
    _buffer.clear();
    _currentIndent = 0;
    _needsBlankLine = false;

    for (final node in nodes) {
      _printNode(node);
    }

    return ensureTrailingNewline(_buffer.toString());
  }

  void _printNode(md.Node node) {
    if (node is md.Element) {
      _printElement(node);
    } else if (node is md.Text) {
      _printText(node);
    } else if (node is md.UnparsedContent) {
      _write(node.textContent);
    }
  }

  void _printElement(md.Element element) {
    switch (element.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        _printHeading(element);
      case 'p':
        _printParagraph(element);
      case 'ul':
        _printUnorderedList(element);
      case 'ol':
        _printOrderedList(element);
      case 'li':
        _printListItem(element);
      case 'blockquote':
        _printBlockquote(element);
      case 'pre':
        _printCodeBlock(element);
      case 'code':
        _printInlineCode(element);
      case 'em':
        _printEmphasis(element);
      case 'strong':
        _printStrong(element);
      case 'a':
        _printLink(element);
      case 'img':
        _printImage(element);
      case 'hr':
        _printHorizontalRule();
      case 'br':
        _printLineBreak();
      case 'table':
        _printTable(element);
      case 'thead':
      case 'tbody':
        _printTableSection(element);
      case 'tr':
        _printTableRow(element);
      case 'th':
      case 'td':
        _printTableCell(element);
      case 'dl':
        _printDefinitionList(element);
      case 'dt':
        _printDefinitionTerm(element);
      case 'dd':
        _printDefinitionDescription(element);
      default:
        // Default: print children
        _printChildren(element);
    }
  }

  void _printHeading(md.Element element) {
    _ensureBlankLine();
    final level = int.parse(element.tag[1]);
    final content = _renderInlineContent(element);
    _writeLine(normalizeHeading(level, content));
    _needsBlankLine = true;
  }

  void _printParagraph(md.Element element) {
    _ensureBlankLine();

    final content = _renderInlineContent(element);

    if (options.proseWrap == ProseWrap.always) {
      final lines = wrapText(
        normalizeWhitespace(content),
        options.printWidth - _currentIndent,
      );
      for (final line in lines) {
        _writeLine(line);
      }
    } else {
      _writeLine(content.trim());
    }

    _needsBlankLine = true;
  }

  void _printUnorderedList(md.Element element) {
    // Only add blank line before top-level lists
    if (_listDepth == 0) {
      _ensureBlankLine();
    }

    _listDepth++;
    for (final child in element.children ?? <md.Node>[]) {
      if (child is md.Element && child.tag == 'li') {
        _writeIndent();

        final bullet = switch (options.ulStyle) {
          UnorderedListStyle.dash => '- ',
          UnorderedListStyle.asterisk => '* ',
          UnorderedListStyle.plus => '+ ',
        };
        _write(bullet);

        _currentIndent += 2;
        _printListItemContent(child);
        _currentIndent -= 2;
      }
    }
    _listDepth--;

    _needsBlankLine = true;
  }

  void _printOrderedList(md.Element element) {
    // Only add blank line before top-level lists
    if (_listDepth == 0) {
      _ensureBlankLine();
    }

    _listDepth++;
    final items = (element.children ?? <md.Node>[])
        .whereType<md.Element>()
        .where((e) => e.tag == 'li')
        .toList();

    final maxNum = items.length;
    final numWidth = maxNum.toString().length;

    for (var i = 0; i < items.length; i++) {
      final num = (i + 1).toString().padLeft(numWidth);
      _writeIndent();
      _write('$num. ');
      _currentIndent += numWidth + 2;
      _printListItemContent(items[i]);
      _currentIndent -= numWidth + 2;
    }
    _listDepth--;

    _needsBlankLine = true;
  }

  void _printListItem(md.Element element) {
    _printListItemContent(element);
  }

  void _printListItemContent(md.Element element) {
    var children = element.children ?? <md.Node>[];

    // Check if it's a checkbox item (has input element as first child)
    final hasCheckbox =
        children.isNotEmpty &&
        children.first is md.Element &&
        (children.first as md.Element).tag == 'input';

    String prefix = '';
    if (hasCheckbox) {
      final inputElement = children.first as md.Element;
      final isChecked = inputElement.attributes['checked'] == 'true';
      prefix = isChecked ? '[x] ' : '[ ] ';
      children = children.skip(1).toList();
    }

    // Simple case: inline content only
    if (children.every(_isInline)) {
      final content = children.map(_renderInlineNode).join();
      if (options.proseWrap == ProseWrap.always) {
        final lines = wrapText(
          normalizeWhitespace(content),
          options.printWidth - _currentIndent - prefix.length,
        );
        _write('$prefix${lines.first}');
        _newLine();
        for (var i = 1; i < lines.length; i++) {
          _writeIndent();
          if (prefix.isNotEmpty) {
            _write('    '); // Indent for checkbox
          }
          _writeLine(lines[i]);
        }
      } else {
        _writeLine('$prefix${content.trim()}');
      }
      return;
    }

    // Complex case: contains block elements (e.g., nested lists)
    // First, collect leading inline content
    final inlineContent = StringBuffer();
    inlineContent.write(prefix);
    var blockStartIndex = 0;

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      if (_isInline(child)) {
        inlineContent.write(_renderInlineNode(child));
      } else {
        blockStartIndex = i;
        break;
      }
    }

    // Write inline content first
    final inlineText = inlineContent.toString().trim();
    if (inlineText.isNotEmpty) {
      _writeLine(inlineText);
    } else {
      // If we have a checkbox but no text usually `[ ]` is followed by something.
      // But if it's just `[ ]` followed by a block, we write the prefix.
      _newLine();
    }

    _needsBlankLine = false;

    // Then process block elements
    for (var i = blockStartIndex; i < children.length; i++) {
      final child = children[i];
      if (!_isInline(child)) {
        _printNode(child);
      }
    }
  }

  void _printBlockquote(md.Element element) {
    _ensureBlankLine();

    // Use a sub-printer to format the content of the blockquote
    // Reduce printWidth by 2 to account for "> " prefix
    final subOptions = options.copyWith(printWidth: options.printWidth - 2);
    final subPrinter = MarkdownPrinter(subOptions);

    final formattedContent = subPrinter.print(element.children ?? []);

    // Split lines and apply '>' prefix
    final lines = formattedContent.trimRight().split('\n');
    for (final line in lines) {
      _writeIndent();
      if (line.isEmpty) {
        _writeLine('>');
      } else {
        _writeLine('> $line');
      }
    }

    _needsBlankLine = true;
  }

  void _printCodeBlock(md.Element element) {
    _ensureBlankLine();

    final codeElement = element.children?.firstOrNull;
    String code = '';
    String? language;

    if (codeElement is md.Element && codeElement.tag == 'code') {
      code = _getTextContent(codeElement);
      language = codeElement.attributes['class']?.replaceFirst('language-', '');
    } else {
      code = _getTextContent(element);
    }

    // Remove trailing newline from code content
    if (code.endsWith('\n')) {
      code = code.substring(0, code.length - 1);
    }

    _writeIndent();
    _writeLine('```${language ?? ''}');

    for (final line in code.split('\n')) {
      _writeIndent();
      _writeLine(line);
    }

    _writeIndent();
    _writeLine('```');

    _needsBlankLine = true;
  }

  void _printInlineCode(md.Element element) {
    final content = _getTextContent(element);
    _write('`$content`');
  }

  void _printEmphasis(md.Element element) {
    final content = _renderInlineContent(element);
    _write('_${content}_');
  }

  void _printStrong(md.Element element) {
    final content = _renderInlineContent(element);
    _write('**$content**');
  }

  void _printLink(md.Element element) {
    final href = element.attributes['href'] ?? '';
    final title = element.attributes['title'];
    final content = _renderInlineContent(element);

    _write('[$content]');
    if (title != null) {
      _write('($href "$title")');
    } else {
      _write('($href)');
    }
  }

  void _printImage(md.Element element) {
    final src = element.attributes['src'] ?? '';
    final alt = element.attributes['alt'] ?? '';
    final title = element.attributes['title'];

    _write('![$alt]');
    if (title != null) {
      _write('($src "$title")');
    } else {
      _write('($src)');
    }
  }

  void _printHorizontalRule() {
    _ensureBlankLine();
    _writeLine('---');
    _needsBlankLine = true;
  }

  void _printLineBreak() {
    _write('  ');
    _newLine();
  }

  void _printTable(md.Element element) {
    _ensureBlankLine();

    // Collect all rows to calculate column widths
    final rows = <List<String>>[];
    final alignments = <String?>[];

    for (final section in element.children ?? <md.Node>[]) {
      if (section is md.Element) {
        for (final row in section.children ?? <md.Node>[]) {
          if (row is md.Element && row.tag == 'tr') {
            final cells = <String>[];
            for (final cell in row.children ?? <md.Node>[]) {
              if (cell is md.Element &&
                  (cell.tag == 'th' || cell.tag == 'td')) {
                cells.add(_renderInlineContent(cell).trim());

                if (cell.tag == 'th' && alignments.length < cells.length) {
                  alignments.add(cell.attributes['align']);
                }
              }
            }
            rows.add(cells);
          }
        }
      }
    }

    if (rows.isEmpty) return;

    // Calculate column widths
    final columnCount = rows
        .map((r) => r.length)
        .reduce((a, b) => a > b ? a : b);
    final columnWidths = List<int>.filled(columnCount, 3); // Minimum width of 3
    for (final row in rows) {
      for (var i = 0; i < row.length; i++) {
        if (row[i].length > columnWidths[i]) {
          columnWidths[i] = row[i].length;
        }
      }
    }

    // Print table
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      _writeIndent();
      _write('|');
      for (var i = 0; i < columnCount; i++) {
        final cell = i < row.length ? row[i] : '';
        _write(' ${cell.padRight(columnWidths[i])} |');
      }
      _newLine();

      // Print separator after header
      if (rowIndex == 0) {
        _writeIndent();
        _write('|');
        for (var i = 0; i < columnCount; i++) {
          final align = i < alignments.length ? alignments[i] : null;
          final dashes = '-' * columnWidths[i];
          if (align == 'center') {
            _write(':$dashes:|');
          } else if (align == 'right') {
            _write(' $dashes:|');
          } else if (align == 'left') {
            _write(':$dashes |');
          } else {
            _write(' $dashes |');
          }
        }
        _newLine();
      }
    }

    _needsBlankLine = true;
  }

  void _printTableSection(md.Element element) {
    _printChildren(element);
  }

  void _printTableRow(md.Element element) {
    _printChildren(element);
  }

  void _printTableCell(md.Element element) {
    _printChildren(element);
  }

  void _printDefinitionList(md.Element element) {
    _ensureBlankLine();

    for (final child in element.children ?? <md.Node>[]) {
      if (child is md.Element) {
        if (child.tag == 'dt') {
          _printDefinitionTerm(child);
        } else if (child.tag == 'dd') {
          _printDefinitionDescription(child);
        }
      }
    }

    _needsBlankLine = true;
  }

  void _printDefinitionTerm(md.Element element) {
    _writeIndent();
    _writeLine(_getTextContent(element).trim());
  }

  void _printDefinitionDescription(md.Element element) {
    _writeIndent();
    final content = _getTextContent(element).trim();

    if (options.proseWrap == ProseWrap.always) {
      final lines = wrapText(
        normalizeWhitespace(content),
        options.printWidth - _currentIndent - 2, // Account for ": "
      );
      _write(': ${lines.first}');
      _newLine();
      for (var i = 1; i < lines.length; i++) {
        _writeIndent();
        _write('  ${lines[i]}');
        _newLine();
      }
    } else {
      _writeLine(': $content');
    }
  }

  void _printText(md.Text text) {
    _write(text.textContent);
  }

  void _printChildren(md.Element element) {
    for (final child in element.children ?? <md.Node>[]) {
      _printNode(child);
    }
  }

  // Helper methods

  String _getTextContent(md.Node node) {
    if (node is md.Text) {
      return node.textContent;
    }
    if (node is md.Element) {
      return (node.children ?? <md.Node>[]).map(_getTextContent).join();
    }
    if (node is md.UnparsedContent) {
      return node.textContent;
    }
    return '';
  }

  String _renderInlineContent(md.Element element) {
    final buffer = StringBuffer();
    for (final child in element.children ?? <md.Node>[]) {
      buffer.write(_renderInlineNode(child));
    }
    return buffer.toString();
  }

  String _renderInlineNode(md.Node node) {
    if (node is md.Text) {
      return node.textContent;
    }
    if (node is md.Element) {
      switch (node.tag) {
        case 'code':
          return '`${_getTextContent(node)}`';
        case 'em':
          return '_${_renderInlineContent(node)}_';
        case 'strong':
          return '**${_renderInlineContent(node)}**';
        case 'a':
          final href = node.attributes['href'] ?? '';
          final title = node.attributes['title'];
          final content = _renderInlineContent(node);
          if (title != null) {
            return '[$content]($href "$title")';
          }
          return '[$content]($href)';
        case 'img':
          final src = node.attributes['src'] ?? '';
          final alt = node.attributes['alt'] ?? '';
          return '![$alt]($src)';
        case 'br':
          return '  \n';
        default:
          return _renderInlineContent(node);
      }
    }
    if (node is md.UnparsedContent) {
      return node.textContent;
    }
    return '';
  }

  bool _isInline(md.Node node) {
    if (node is md.Text) return true;
    if (node is md.Element) {
      return const [
        'code',
        'em',
        'strong',
        'a',
        'img',
        'br',
      ].contains(node.tag);
    }
    return true;
  }

  void _write(String text) {
    _buffer.write(text);
  }

  void _writeLine(String text) {
    _buffer.writeln(text);
  }

  void _newLine() {
    _buffer.writeln();
  }

  void _writeIndent() {
    if (_currentIndent > 0) {
      _buffer.write(' ' * _currentIndent);
    }
  }

  void _ensureBlankLine() {
    if (_needsBlankLine) {
      _newLine();
    }
    _needsBlankLine = false;
  }
}
