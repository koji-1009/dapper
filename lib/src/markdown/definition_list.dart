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

    // Check if this could be a term (non-empty, not starting with special chars)
    if (_isPotentialTerm(line) && i + 1 < lines.length) {
      // Look ahead for definitions
      var j = i + 1;
      final definitions = <String>[];

      while (j < lines.length) {
        final nextLine = lines[j];
        final match = _definitionMatch(nextLine);
        if (match != null) {
          definitions.add(match);
          j++;
        } else if (nextLine.trim().isEmpty && j + 1 < lines.length) {
          // Allow one blank line between definitions
          final afterBlank = lines[j + 1];
          if (_definitionMatch(afterBlank) != null) {
            j++;
          } else {
            break;
          }
        } else {
          break;
        }
      }

      if (definitions.isNotEmpty) {
        // This is a definition list, flush markdown buffer first
        flushMarkdown();

        // Collect all consecutive definition items
        final items = <DefinitionItem>[
          DefinitionItem(line.trim(), definitions),
        ];

        // Continue looking for more items
        while (j < lines.length) {
          // Skip blank lines
          while (j < lines.length && lines[j].trim().isEmpty) {
            j++;
          }

          if (j >= lines.length) break;

          final nextTerm = lines[j];
          if (_isPotentialTerm(nextTerm) && j + 1 < lines.length) {
            final nextDefs = <String>[];
            var k = j + 1;
            while (k < lines.length) {
              final defLine = lines[k];
              final match = _definitionMatch(defLine);
              if (match != null) {
                nextDefs.add(match);
                k++;
              } else {
                break;
              }
            }
            if (nextDefs.isNotEmpty) {
              items.add(DefinitionItem(nextTerm.trim(), nextDefs));
              j = k;
              continue;
            }
          }
          break;
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
