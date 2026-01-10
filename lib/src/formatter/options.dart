/// Formatting options for the Dapper formatter.
///
/// These options control how the formatter processes Markdown and YAML files.
library;

/// Controls how prose (paragraph text) is wrapped.
enum ProseWrap {
  /// Always wrap prose at [FormatOptions.printWidth].
  always,

  /// Never wrap prose; keep original line breaks.
  never,

  /// Preserve original wrapping behavior.
  preserve,
}

/// Options for controlling formatter behavior.
class FormatOptions {
  /// Maximum line width for wrapping.
  ///
  /// Default is 80 characters, matching Prettier's default.
  final int printWidth;

  /// Number of spaces per indentation level.
  ///
  /// Default is 2 spaces.
  final int tabWidth;

  /// How to handle prose wrapping in paragraphs.
  ///
  /// Default is [ProseWrap.preserve].
  final ProseWrap proseWrap;

  /// Whether to use single quotes for YAML strings.
  ///
  /// Default is false (use double quotes).
  final bool singleQuote;

  /// Creates formatting options with the specified values.
  const FormatOptions({
    this.printWidth = 80,
    this.tabWidth = 2,
    this.proseWrap = ProseWrap.preserve,
    this.singleQuote = false,
  });

  /// Default formatting options matching Prettier defaults.
  static const FormatOptions defaults = FormatOptions();

  /// Creates a copy with the specified fields replaced.
  FormatOptions copyWith({
    int? printWidth,
    int? tabWidth,
    ProseWrap? proseWrap,
    bool? singleQuote,
  }) {
    return FormatOptions(
      printWidth: printWidth ?? this.printWidth,
      tabWidth: tabWidth ?? this.tabWidth,
      proseWrap: proseWrap ?? this.proseWrap,
      singleQuote: singleQuote ?? this.singleQuote,
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
          singleQuote == other.singleQuote;

  @override
  int get hashCode => Object.hash(printWidth, tabWidth, proseWrap, singleQuote);

  @override
  String toString() =>
      'FormatOptions('
      'printWidth: $printWidth, '
      'tabWidth: $tabWidth, '
      'proseWrap: $proseWrap, '
      'singleQuote: $singleQuote)';
}
