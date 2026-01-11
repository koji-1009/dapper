/// Formatting options for the Dapper formatter.
///
/// These options control how the formatter processes Markdown and YAML files.
/// Some options apply to both formats, while others are format-specific.
///
/// ## Option Applicability
///
/// | Option       | Markdown | YAML |
/// |--------------|----------|------|
/// | `tabWidth`   | ✓        | ✓    |
/// | `printWidth` | ✓        | ✗    |
/// | `proseWrap`  | ✓        | ✗    |
///
/// ## Example
///
/// ```dart
/// // Custom options
/// final options = FormatOptions(
///   tabWidth: 4,           // 4-space indent (both Markdown and YAML)
///   printWidth: 100,       // Wrap at 100 chars (Markdown only)
///   proseWrap: ProseWrap.always,  // Always wrap prose (Markdown only)
/// );
///
/// // Format with options
/// final md = formatMarkdown(content, options: options);
/// final yaml = formatYaml(content, options: options);
/// ```
library;

/// Controls how prose (paragraph text) is wrapped in Markdown.
///
/// This option only affects Markdown formatting and has no effect on YAML.
enum ProseWrap {
  /// Always wrap prose at [FormatOptions.printWidth].
  ///
  /// Long paragraphs will be split into multiple lines.
  always,

  /// Never wrap prose; keep original line breaks.
  ///
  /// Lines will not be wrapped regardless of length.
  never,

  /// Preserve original wrapping behavior.
  ///
  /// Existing line breaks are kept as-is.
  preserve,
}

/// Style for unordered list bullets in Markdown.
enum UnorderedListStyle {
  /// Use hyphens for bullets (e.g. - item).
  dash,

  /// Use asterisks for bullets (e.g. * item).
  asterisk,

  /// Use plus signs for bullets (e.g. + item).
  plus,
}

/// Options for controlling formatter behavior.
///
/// Use these options to customize how Markdown and YAML files are formatted.
/// All options have sensible defaults matching Prettier's behavior.
class FormatOptions {
  /// Maximum line width for wrapping.
  ///
  /// **Applies to:** Markdown only
  ///
  /// Used when [proseWrap] is set to [ProseWrap.always].
  /// Default is 80 characters, matching Prettier's default.
  final int printWidth;

  /// Number of spaces per indentation level.
  ///
  /// **Applies to:** Markdown and YAML
  ///
  /// - Markdown: List item indentation, code block indentation
  /// - YAML: Nested map and list indentation
  ///
  /// Default is 2 spaces.
  final int tabWidth;

  /// How to handle prose wrapping in paragraphs.
  ///
  /// **Applies to:** Markdown only
  ///
  /// Controls whether long paragraphs should be wrapped at [printWidth].
  /// Default is [ProseWrap.preserve].
  final ProseWrap proseWrap;

  /// Style for unordered list bullets.
  ///
  /// **Applies to:** Markdown only
  ///
  /// Default is [UnorderedListStyle.dash].
  final UnorderedListStyle ulStyle;

  /// Creates formatting options with the specified values.
  ///
  /// All parameters are optional and have sensible defaults:
  /// - [printWidth]: 80
  /// - [tabWidth]: 2
  /// - [proseWrap]: [ProseWrap.preserve]
  /// - [ulStyle]: [UnorderedListStyle.dash]
  const FormatOptions({
    this.printWidth = 80,
    this.tabWidth = 2,
    this.proseWrap = ProseWrap.preserve,
    this.ulStyle = UnorderedListStyle.dash,
  });

  /// Default formatting options matching Prettier defaults.
  static const FormatOptions defaults = FormatOptions();

  /// Creates a copy with the specified fields replaced.
  FormatOptions copyWith({
    int? printWidth,
    int? tabWidth,
    ProseWrap? proseWrap,
    UnorderedListStyle? ulStyle,
  }) {
    return FormatOptions(
      printWidth: printWidth ?? this.printWidth,
      tabWidth: tabWidth ?? this.tabWidth,
      proseWrap: proseWrap ?? this.proseWrap,
      ulStyle: ulStyle ?? this.ulStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormatOptions &&
          runtimeType == other.runtimeType &&
          printWidth == other.printWidth &&
          tabWidth == other.tabWidth &&
          proseWrap == other.proseWrap &&
          ulStyle == other.ulStyle;

  @override
  int get hashCode => Object.hash(printWidth, tabWidth, proseWrap, ulStyle);

  @override
  String toString() =>
      'FormatOptions('
      'printWidth: $printWidth, '
      'tabWidth: $tabWidth, '
      'proseWrap: $proseWrap, '
      'ulStyle: $ulStyle)';
}
