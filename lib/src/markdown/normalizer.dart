/// Markdown normalization rules.
///
/// Implements Prettier-style normalization for Markdown elements.
library;

/// Normalizes heading to ATX style.
///
/// Ensures consistent spacing: `# Heading` (one space after #).
String normalizeHeading(int level, String content) {
  final clampedLevel = level.clamp(1, 6);
  final prefix = '#' * clampedLevel;
  final trimmedContent = content.trim();

  if (trimmedContent.isEmpty) {
    return prefix;
  }

  return '$prefix $trimmedContent';
}
