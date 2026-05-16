/// Definition list syntax for markdown.
///
/// Parses definition lists in the format:
/// ```
/// Term 1
/// : Definition 1
///
/// Term 2
/// : Definition 2a
/// : Definition 2b
/// ```
library;

// Cached regular expressions
final _definitionPattern = RegExp(r'^:\s+(.+)$');
final _orderedListPattern = RegExp(r'^\d+\.');

/// Represents a definition list.
class DefinitionList {
  const DefinitionList(this.items);
  final List<DefinitionItem> items;
}

/// Represents a single term with its definitions.
class DefinitionItem {
  const DefinitionItem(this.term, this.definitions);
  final String term;
  final List<String> definitions;
}

/// Represents a segment of the document that is either regular markdown
/// or a definition list.
sealed class DocumentSegment {
  const DocumentSegment();
}

/// A segment containing regular markdown content.
class MarkdownSegment extends DocumentSegment {
  const MarkdownSegment(this.content);
  final String content;
}

/// A segment containing a definition list.
class DefinitionListSegment extends DocumentSegment {
  const DefinitionListSegment(this.definitionList);
  final DefinitionList definitionList;
}

/// Parses markdown into segments, extracting definition lists.
List<DocumentSegment> parseDocumentSegments(String markdown) {
  final lines = markdown.split('\n');
  final segments = <DocumentSegment>[];
  final markdownBuffer = <String>[];
  var i = 0;

  void flushMarkdown() {
    if (markdownBuffer.isNotEmpty) {
      segments.add(MarkdownSegment(markdownBuffer.join('\n')));
      markdownBuffer.clear();
    }
  }

  while (i < lines.length) {
    final line = lines[i];

    if (_isPotentialTerm(line) && i + 1 < lines.length) {
      final firstDefs = _collectDefinitions(lines, i + 1);

      if (firstDefs.definitions.isNotEmpty) {
        flushMarkdown();

        final items = <DefinitionItem>[
          DefinitionItem(line.trim(), firstDefs.definitions),
        ];
        var j = firstDefs.nextIndex;

        // Continue collecting subsequent term/definition pairs.
        while (j < lines.length) {
          while (j < lines.length && lines[j].trim().isEmpty) {
            j++;
          }
          if (j >= lines.length) break;

          final nextTerm = lines[j];
          if (!_isPotentialTerm(nextTerm) || j + 1 >= lines.length) break;

          final nextDefs = _collectDefinitions(lines, j + 1);
          if (nextDefs.definitions.isEmpty) break;

          items.add(DefinitionItem(nextTerm.trim(), nextDefs.definitions));
          j = nextDefs.nextIndex;
        }

        segments.add(DefinitionListSegment(DefinitionList(items)));
        i = j;
        continue;
      }
    }

    markdownBuffer.add(line);
    i++;
  }

  flushMarkdown();
  return segments;
}

/// Collects consecutive `: definition` lines starting at [fromIndex],
/// tolerating a single blank line between definitions.
({List<String> definitions, int nextIndex}) _collectDefinitions(
  List<String> lines,
  int fromIndex,
) {
  final definitions = <String>[];
  var j = fromIndex;
  while (j < lines.length) {
    final match = _definitionMatch(lines[j]);
    if (match != null) {
      definitions.add(match);
      j++;
      continue;
    }
    if (lines[j].trim().isEmpty &&
        j + 1 < lines.length &&
        _definitionMatch(lines[j + 1]) != null) {
      j++;
      continue;
    }
    break;
  }
  return (definitions: definitions, nextIndex: j);
}

bool _isPotentialTerm(String line) {
  return line.isNotEmpty &&
      !line.startsWith(':') &&
      !line.startsWith('#') &&
      !line.startsWith('-') &&
      !line.startsWith('*') &&
      !line.startsWith('>') &&
      !line.startsWith('`') &&
      !line.startsWith('|') &&
      !line.startsWith(' ') &&
      !line.startsWith('\t') &&
      !_orderedListPattern.hasMatch(line);
}

String? _definitionMatch(String line) {
  final match = _definitionPattern.firstMatch(line);
  return match?.group(1);
}

/// Formats a definition list to markdown string.
String formatDefinitionList(DefinitionList list) {
  final buffer = StringBuffer();

  for (var i = 0; i < list.items.length; i++) {
    final item = list.items[i];
    buffer.writeln(item.term);
    for (final def in item.definitions) {
      buffer.writeln(': $def');
    }
    if (i < list.items.length - 1) {
      buffer.writeln();
    }
  }

  return buffer.toString();
}

/// Checks if the markdown contains definition list syntax.
bool hasDefinitionLists(String markdown) {
  final lines = markdown.split('\n');
  for (var i = 0; i < lines.length - 1; i++) {
    final current = lines[i];
    final next = lines[i + 1];

    if (_isPotentialTerm(current) && next.startsWith(': ')) {
      return true;
    }
  }
  return false;
}
