/// Markdown normalization rules.
///
/// Implements Prettier-style normalization for Markdown elements.
library;

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
