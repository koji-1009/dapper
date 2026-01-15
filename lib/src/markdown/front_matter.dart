/// Front matter parser.
///
/// Extracts YAML front matter from the beginning of a Markdown document.
library;

/// Result of front matter extraction.
class FrontMatterResult {
  const FrontMatterResult({this.frontMatter, required this.content});

  /// The YAML front matter content (without delimiters), or null if none.
  final String? frontMatter;

  /// The remaining Markdown content after the front matter.
  final String content;

  /// Whether front matter was found.
  bool get hasFrontMatter => frontMatter != null;
}

/// Extracts YAML front matter from the beginning of a document.
///
/// Front matter must:
/// - Start at the very beginning of the document
/// - Be delimited by `---` lines
/// - End with a `---` line
///
/// Example:
/// ```yaml
/// ---
/// title: My Document
/// author: John Doe
/// ---
/// # Document content starts here
/// ```
FrontMatterResult extractFrontMatter(String input) {
  if (input.isEmpty) {
    return FrontMatterResult(content: input);
  }

  final lines = input.split('\n');

  // Front matter must start with ---
  if (lines.isEmpty || lines[0].trim() != '---') {
    return FrontMatterResult(content: input);
  }

  // Find the closing ---
  int endIndex = -1;
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      endIndex = i;
      break;
    }
  }

  if (endIndex == -1) {
    // No closing delimiter found, treat as no front matter
    return FrontMatterResult(content: input);
  }

  // Extract front matter content (lines between delimiters)
  final frontMatterLines = lines.sublist(1, endIndex);
  final frontMatter = frontMatterLines.join('\n');

  // Remaining content after front matter
  final contentLines = lines.sublist(endIndex + 1);
  // Remove leading empty line if present
  final content = contentLines.isNotEmpty && contentLines[0].trim().isEmpty
      ? contentLines.sublist(1).join('\n')
      : contentLines.join('\n');

  return FrontMatterResult(frontMatter: frontMatter, content: content);
}

/// Reconstructs a document with front matter.
String withFrontMatter(String? frontMatter, String content) {
  if (frontMatter == null || frontMatter.isEmpty) {
    return content;
  }

  return '---\n$frontMatter\n---\n\n$content';
}
