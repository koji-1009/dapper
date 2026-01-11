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

/// Removes trailing whitespace from each line.
String trimTrailingWhitespace(String text) {
  return text.split('\n').map((line) => line.trimRight()).join('\n');
}

/// Ensures the text ends with exactly one newline.
String ensureTrailingNewline(String text) {
  final trimmed = text.trimRight();
  return trimmed.isEmpty ? '' : '$trimmed\n';
}

/// Counts the display width of a string.
///
/// Returns the character count (string length).
int displayWidth(String text) {
  return text.length;
}

/// Creates an indentation string of the specified width.
String indent(int width, {bool useTabs = false, int tabWidth = 2}) {
  if (width <= 0) return '';

  if (useTabs) {
    final tabs = width ~/ tabWidth;
    final spaces = width % tabWidth;
    return '\t' * tabs + ' ' * spaces;
  }

  return ' ' * width;
}

/// Repeats a string [count] times.
String repeat(String text, int count) {
  if (count <= 0) return '';
  return text * count;
}
