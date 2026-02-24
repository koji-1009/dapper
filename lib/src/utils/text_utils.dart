/// Text utility functions for formatting.
library;

/// Wraps text at the specified width, breaking at word boundaries.
///
/// Returns a list of lines, each no longer than [width] characters
/// (unless a single word exceeds the width).
List<String> wrapText(String text, int width) {
  if (width <= 0) {
    throw ArgumentError.value(width, 'width', 'Must be positive');
  }

  if (text.isEmpty) {
    return [''];
  }

  final words = text.split(RegExp(r'\s+'));
  final lines = <String>[];
  final buffer = StringBuffer();

  for (final word in words) {
    if (word.isEmpty) continue;

    if (buffer.isEmpty) {
      buffer.write(word);
    } else if (buffer.length + 1 + word.length <= width) {
      buffer.write(' $word');
    } else {
      lines.add(buffer.toString());
      buffer.clear();
      buffer.write(word);
    }
  }

  if (buffer.isNotEmpty) {
    lines.add(buffer.toString());
  }

  return lines.isEmpty ? [''] : lines;
}

/// Normalizes whitespace in text.
///
/// - Collapses multiple spaces/tabs into single space
/// - Trims leading and trailing whitespace
String normalizeWhitespace(String text) {
  return text.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
}

/// Ensures the text ends with exactly one newline.
String ensureTrailingNewline(String text) {
  final trimmed = text.trimRight();
  return trimmed.isEmpty ? '' : '$trimmed\n';
}
