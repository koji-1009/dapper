/// Markdown formatter.
///
/// The main entry point for formatting Markdown documents.
library;

import 'package:markdown/markdown.dart' as md;

import '../options.dart';
import 'ast_printer.dart';
import 'definition_list.dart';
import 'front_matter.dart';

/// Formats a Markdown document according to the specified options.
///
/// Example:
/// ```dart
/// final formatter = MarkdownFormatter();
/// final formatted = formatter.format('''
/// # Hello
///
/// *world*
/// ''');
/// print(formatted);
/// // Output:
/// // # Hello
/// //
/// // _world_
/// ```
class MarkdownFormatter {
  final FormatOptions options;

  /// Creates a new Markdown formatter with the given options.
  ///
  /// If no options are provided, defaults are used.
  MarkdownFormatter([FormatOptions? options])
    : options = options ?? FormatOptions.defaults;

  /// Formats the given Markdown string.
  ///
  /// Returns the formatted Markdown string.
  ///
  /// Front matter (YAML metadata at the start) is preserved unchanged.
  /// Definition lists are supported and formatted.
  String format(String markdown) {
    if (markdown.isEmpty) {
      return '';
    }

    // Extract front matter if present
    final fmResult = extractFrontMatter(markdown);

    // Format the content (handling definition lists as segments)
    final formattedContent = _formatContent(fmResult.content);

    // Reconstruct with front matter if it was present
    if (fmResult.hasFrontMatter) {
      return withFrontMatter(fmResult.frontMatter, formattedContent);
    }

    return formattedContent;
  }

  String _formatContent(String content) {
    // Check for definition lists
    if (!hasDefinitionLists(content)) {
      // No definition lists, format normally
      return _formatMarkdown(content);
    }

    // Parse into segments
    final segments = parseDocumentSegments(content);
    final buffer = StringBuffer();
    var endsWithNewlines = 0; // Track trailing newlines

    for (final segment in segments) {
      switch (segment) {
        case MarkdownSegment():
          final formatted = _formatMarkdown(segment.content);
          if (formatted.trim().isNotEmpty) {
            buffer.write(formatted);
            endsWithNewlines = _countTrailingNewlines(formatted);
          }
        case DefinitionListSegment():
          // Ensure blank line before definition list
          if (buffer.isNotEmpty && endsWithNewlines < 2) {
            while (endsWithNewlines < 2) {
              buffer.writeln();
              endsWithNewlines++;
            }
          }
          final dlContent = formatDefinitionList(segment.definitionList);
          buffer.write(dlContent);
          buffer.writeln();
          endsWithNewlines = _countTrailingNewlines('$dlContent\n');
      }
    }

    return buffer.toString();
  }

  int _countTrailingNewlines(String text) {
    var count = 0;
    for (var i = text.length - 1; i >= 0 && text[i] == '\n'; i--) {
      count++;
    }
    return count;
  }

  String _formatMarkdown(String markdown) {
    if (markdown.trim().isEmpty) {
      return '';
    }

    // Parse the markdown document
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    final lines = markdown.split('\n');
    final nodes = document.parseLines(lines);

    // Print the AST back to formatted markdown
    final printer = MarkdownPrinter(options);
    return printer.print(nodes);
  }
}

/// Convenience function to format Markdown with default options.
String formatMarkdown(String markdown, {FormatOptions? options}) {
  final formatter = MarkdownFormatter(options);
  return formatter.format(markdown);
}
