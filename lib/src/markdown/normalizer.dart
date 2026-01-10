/// Markdown normalization rules.
///
/// Implements Prettier-style normalization for Markdown elements.
library;

/// Normalizes emphasis markers from `*` to `_` where appropriate.
///
/// Following Prettier's convention:
/// - `*text*` becomes `_text_`
/// - `**text**` stays as `**text**` (strong emphasis)
/// - `***text***` becomes `_**text**_` or `**_text_**`
/// - Emphasis within words stays as-is (e.g., `foo*bar*baz`)
String normalizeEmphasis(String text) {
  // Pattern for emphasis not within words:
  // - Start of string or non-word character before `*`
  // - `*content*` where content doesn't contain unescaped `*`
  // - End of string or non-word character after `*`

  // Handle single emphasis: *text* -> _text_
  // Only convert when not part of a word (word boundaries)
  final singleEmphasisPattern = RegExp(r'(?<![*\w])(\*)([^*\n]+?)\1(?![*\w])');

  var result = text;

  // Replace *text* with _text_ when at word boundaries
  result = result.replaceAllMapped(singleEmphasisPattern, (match) {
    final content = match.group(2)!;
    // Don't convert if content starts or ends with space
    if (content.startsWith(' ') || content.endsWith(' ')) {
      return match.group(0)!;
    }
    return '_${content}_';
  });

  // Handle ***text*** -> **_text_** (bold + italic)
  final boldItalicPattern = RegExp(
    r'(?<![*\w])\*\*\*([^*\n]+?)\*\*\*(?![*\w])',
  );
  result = result.replaceAllMapped(boldItalicPattern, (match) {
    final content = match.group(1)!;
    return '**_${content}_**';
  });

  return result;
}

/// Normalizes horizontal rules to `---`.
///
/// Converts various horizontal rule styles:
/// - `***`, `* * *` -> `---`
/// - `___`, `_ _ _` -> `---`
/// - `---`, `- - -` -> `---`
String normalizeHorizontalRule(String text) {
  // Match various horizontal rule patterns
  final hrPattern = RegExp(
    r'^[ \t]*([-*_])[ \t]*(?:\1[ \t]*){2,}$',
    multiLine: true,
  );

  return text.replaceAllMapped(hrPattern, (match) => '---');
}

/// Normalizes list markers.
///
/// - Unordered lists: various markers (`*`, `+`) -> `-`
/// - Ordered lists: keep numbers, normalize spacing
String normalizeUnorderedListMarker(String marker) {
  // Convert *, + to -
  if (marker == '*' || marker == '+') {
    return '-';
  }
  return marker;
}

/// Calculates the proper indentation for ordered list items.
///
/// For ordered lists, the content should align based on the widest number:
/// ```
/// 1. First
/// 2. Second
/// ...
/// 10. Tenth (number width = 2)
/// ```
int orderedListContentIndent(int maxNumber, int tabWidth) {
  final numberWidth = maxNumber.toString().length;
  // Number + dot + space
  return numberWidth + 2;
}

/// Normalizes a code fence marker to use backticks.
///
/// Converts `~~~` to ` ``` `.
String normalizeCodeFence(String fence) {
  if (fence.startsWith('~')) {
    return '`' * fence.length;
  }
  return fence;
}

/// Normalizes heading to ATX style.
///
/// Ensures consistent spacing: `# Heading` (one space after #).
String normalizeHeading(int level, String content) {
  if (level < 1) level = 1;
  if (level > 6) level = 6;

  final prefix = '#' * level;
  final trimmedContent = content.trim();

  if (trimmedContent.isEmpty) {
    return prefix;
  }

  return '$prefix $trimmedContent';
}
