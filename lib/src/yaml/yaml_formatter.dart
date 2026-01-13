/// YAML formatter.
///
library;

import 'package:yaml/yaml.dart';

import '../options.dart';

/// Formats a YAML document according to the specified options.
///
/// Example:
/// ```dart
/// final formatter = YamlFormatter();
/// final formatted = formatter.format('''
/// name:   myapp
/// version: 1.0.0
/// dependencies:
///     flutter:
///       sdk: flutter
/// ''');
/// print(formatted);
/// // Output:
/// // name: myapp
/// // version: 1.0.0
/// // dependencies:
/// //   flutter:
/// //     sdk: flutter
/// ```
class YamlFormatter {
  /// The options used for formatting.
  final FormatOptions options;

  /// Creates a new YAML formatter with the given options.
  YamlFormatter([FormatOptions? options])
    : options = options ?? FormatOptions.defaults;

  /// Formats the given YAML string.
  ///
  /// Returns the formatted YAML string.
  String format(String yaml) {
    if (yaml.trim().isEmpty) {
      return '';
    }

    // Use loadYamlNode to access source spans for comment preservation
    final node = loadYamlNode(yaml);
    final printer = _YamlPrinter(options, yaml);
    return printer.print(node);
  }
}

/// Convenience function to format YAML with default options.
String formatYaml(String yaml, {FormatOptions? options}) {
  final formatter = YamlFormatter(options);
  return formatter.format(yaml);
}

class _YamlPrinter {
  final FormatOptions options;
  final String source;
  final StringBuffer _buffer = StringBuffer();
  int _indentLevel = 0;
  int _lastOffset = 0;

  _YamlPrinter(this.options, this.source);

  String print(YamlNode node) {
    _buffer.clear();
    _lastOffset = 0;

    // Handle leading comments (before the first node)
    if (node.span.start.offset > 0) {
      _printGap(0, node.span.start.offset, trimLeadingNewlines: true);
    }

    _lastOffset = node.span.start.offset;
    _printNode(node, inline: false);

    // Handle trailing comments (after the last node)
    if (_lastOffset < source.length) {
      _printGap(_lastOffset, source.length);
    }

    return _ensureTrailingNewline(_buffer.toString());
  }

  void _printGap(
    int start,
    int end, {
    int? indentLevel,
    bool trimLeadingNewlines = false,
    int maxBlankLines = 1,
  }) {
    if (start >= end) return;
    final gap = source.substring(start, end);

    // Extract comments from the gap
    final lines = gap.split('\n');

    var trimming = trimLeadingNewlines;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];

      if (trimming) {
        if (line.trim().isEmpty) continue;
        trimming = false;
      }

      // Check for comments
      final commentIndex = line.indexOf('#');
      if (commentIndex != -1) {
        final comment = line.substring(commentIndex);

        if (i == 0 && start > 0 && !gap.startsWith('\n')) {
          _write(' $comment');
        } else {
          final originalIndentStr = line.substring(0, commentIndex);
          final originalIndentWidth = originalIndentStr.length;

          final targetLevel = indentLevel ?? _indentLevel;
          final targetIndentWidth = targetLevel * options.tabWidth;

          int effectiveLevel = targetLevel;
          if (originalIndentWidth < targetIndentWidth) {
            // Round down to nearest level
            effectiveLevel = (originalIndentWidth / options.tabWidth).round();
          }

          _buffer.write(' ' * (effectiveLevel * options.tabWidth));
          _write(comment);
        }
      }

      // Output newline if this is not the last segment
      if (i < lines.length - 1) {
        // Limit consecutive newlines based on maxBlankLines
        // maxBlankLines = 1 means we allow 1 blank line (which is 2 consecutive newlines)
        // \n\n ends with \n\n.
        final limit = maxBlankLines + 1;
        final currentNewlines = _countTrailingNewlines(_buffer.toString());

        if (currentNewlines < limit) {
          _newLine();
        }
      }
    }
  }

  int _countTrailingNewlines(String s) {
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      if (s[i] == '\n') {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  void _printNode(YamlNode node, {required bool inline}) {
    if (node is YamlMap) {
      _printMap(node, inline: inline);
    } else if (node is YamlList) {
      _printList(node);
    } else {
      _printScalar(node);
    }
  }

  void _printMap(YamlMap map, {required bool inline}) {
    // Note: map.isEmpty check is handled by caller logic flow usually, but good to check
    if (map.isEmpty) {
      _write('{}');
      _lastOffset = map.span.end.offset;
      return;
    }

    // Keys are sorted by their appearance in the source to preserve order
    final sortedKeys = map.nodes.keys.toList()
      ..sort(
        (a, b) => map.nodes[a]!.span.start.offset.compareTo(
          map.nodes[b]!.span.start.offset,
        ),
      );

    for (var i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final keyNode = map.nodes.keys.firstWhere(
        (k) => k == key,
      ); // Get the key node to access span
      final valueNode = map.nodes[key]!;

      // Gap before key
      // TRIM FIX: Trim leading newlines for the first key to enforce tight padding after parent
      _printGap(
        _lastOffset,
        (keyNode as YamlNode).span.start.offset,
        trimLeadingNewlines: i == 0,
      );

      // If gap put us on a new line, we need indent.
      // But _printGap handles writing.
      // We need to ensure we are on a fresh line if not inline?
      // Actually _printGap logic needs to be smarter about indents.

      // Simplified approach: _printGap outputs comments.
      // We then decide if we need a newline/indent for the key.

      if (i > 0 || !inline) {
        if (!inline && _buffer.isEmpty) {
          // Don't add newline at the very beginning of the file/buffer
        } else if (!_buffer.toString().endsWith('\n')) {
          _newLine();
        }
        if (!inline && _buffer.isNotEmpty) {
          _writeIndent();
        } else if (inline) {
          _writeIndent();
        }
      } else if (inline && i == 0) {
        // Key follows something on same line (e.g. "- key:")
        if (_buffer.toString().endsWith('\n')) {
          _writeIndent();
        }
      }

      final keyText = keyNode.toString(); // or keyNode.value.toString()
      _write('$keyText:');

      _lastOffset = keyNode.span.end.offset;

      // Gap between key and value (inline comments?)
      // If value is simple, comments stay on same level.
      // If value is complex (block), comments usually belong to the child block?
      // Or they are just comments on the key.
      // But visually, if they are on the next line, they should be indented if the value is indented.
      final isScalarOrEmpty =
          _isScalar(valueNode) ||
          (valueNode is YamlMap && valueNode.isEmpty) ||
          (valueNode is YamlList && valueNode.isEmpty);

      final gapIndent = isScalarOrEmpty ? null : _indentLevel + 1;

      // Rule: Reduce blank lines to 0 between a structured key and its first child
      // if it's a block value.
      final maxBlankLines = isScalarOrEmpty ? 1 : 0;

      _printGap(
        _lastOffset,
        valueNode.span.start.offset,
        indentLevel: gapIndent,
        maxBlankLines: maxBlankLines,
      );
      _lastOffset = valueNode.span.start.offset;

      // Ensure we don't print "null" for implicit null values
      if (valueNode.span.length == 0 && valueNode.value == null) {
        // Implicit null, do nothing
        _lastOffset = valueNode.span.end.offset;
      } else if (isScalarOrEmpty) {
        if (!_buffer.toString().endsWith(' ') &&
            !_buffer.toString().endsWith('\n')) {
          _write(' ');
        }
        _printNode(valueNode, inline: true);
        _lastOffset = valueNode.span.end.offset;
      } else {
        if (!_buffer.toString().endsWith('\n')) {
          _newLine();
        }
        _indentLevel++;
        _printNode(valueNode, inline: false);
        _indentLevel--;
        // Map/List printing updates _lastOffset internally (including trailing gaps).
        // Do not overwrite _lastOffset here.
      }
    }

    // Process trailing comments/content belonging to this map but after the last value
    if (_lastOffset < map.span.end.offset) {
      _printGap(_lastOffset, map.span.end.offset, indentLevel: _indentLevel);
      _lastOffset = map.span.end.offset;
    }
  }

  void _printList(YamlList list) {
    if (list.isEmpty) {
      _write('[]');
      _lastOffset = list.span.end.offset;
      return;
    }

    var isFirst = true;
    for (final node in list.nodes) {
      // Gap before item
      // TRIM FIX: Trim leading newlines for first item
      _printGap(
        _lastOffset,
        node.span.start.offset,
        trimLeadingNewlines: isFirst,
      );
      isFirst = false;

      if (!_buffer.toString().endsWith('\n')) {
        _newLine();
      }

      _writeIndent();
      _write('- ');

      _lastOffset = node.span.start.offset;

      if (_isScalar(node)) {
        _printNode(node, inline: true);
        _lastOffset = node.span.end.offset;
      } else if (node is YamlMap) {
        // Special handling for map inside list
        if (node.isEmpty) {
          _writeLine('{}');
          _lastOffset = node.span.end.offset;
        } else {
          // We need to print the first entry on the same line
          // But _printMap logic handles "inline".
          // However, _printMap expects to handle keys.

          // Delegate to _printMap with inline=true for the first key
          // INDENTATION FIX: Increment indent level so subsequent keys align with the first key content
          _indentLevel++;
          _printMap(node, inline: true);
          _indentLevel--;
          // _printMap updates _lastOffset
        }
      } else if (node is YamlList) {
        if (node.isEmpty) {
          _writeLine('[]');
          _lastOffset = node.span.end.offset;
        } else {
          _newLine();
          _indentLevel++;
          _printNode(node, inline: false);
          _indentLevel--;
          // inner list updates _lastOffset
        }
      }
    }

    // Process trailing comments belonging to this list
    if (_lastOffset < list.span.end.offset) {
      _printGap(_lastOffset, list.span.end.offset, indentLevel: _indentLevel);
      _lastOffset = list.span.end.offset;
    }
  }

  void _printScalar(YamlNode node) {
    final scalar = node as YamlScalar;
    // Determine quoting...
    final value = scalar.value;

    // Only quote strings. Primitives (null, bool, num) should differ to their string representation
    if (value is! String) {
      _write(value == null ? 'null' : value.toString());
      return;
    }

    String text;
    if (scalar.style == ScalarStyle.SINGLE_QUOTED) {
      text = "'${value.toString()}'";
    } else if (scalar.style == ScalarStyle.DOUBLE_QUOTED) {
      text = '"${value.toString()}"';
    } else if (scalar.style == ScalarStyle.LITERAL) {
      _printBlockScalar(value.toString(), '|');
      return;
    } else if (scalar.style == ScalarStyle.FOLDED) {
      _printBlockScalar(value.toString(), '>');
      return;
    } else {
      text = value.toString();
      if (_needsQuoting(text)) {
        text = '"${text.replaceAll('"', r'\"').replaceAll('\n', r'\n')}"';
      }
    }
    _write(text);
  }

  void _printBlockScalar(String value, String indicator) {
    // Determine chomping indicator (clip, strip, keep)
    // For simplicity, we default to clip (newline at end preserved) unless ends with multiple newlines
    // But basic implementation:
    // |
    //   line1
    //   line2

    var suffix = '';
    if (value.endsWith('\n\n')) {
      suffix = '+'; // keep
    } else if (!value.endsWith('\n')) {
      suffix = '-'; // strip
    }

    _write('$indicator$suffix');

    final lines = value.split('\n');
    // If strip, the last empty string from split is redundant?
    // 'a\nb'.split('\n') -> ['a', 'b']
    // 'a\n'.split('\n') -> ['a', '']

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty && i == lines.length - 1 && !value.endsWith('\n\n')) {
        // Skip last empty line from split if it's just the trailing newline
        continue;
      }

      _newLine();
      if (line.isNotEmpty) {
        // Allow content to be indented relative to the parent key/list item
        _indentLevel++;
        _writeIndent();
        _write(line);
        _indentLevel--;
      }
    }
  }

  // ... helpers like _write, _writeLine, _isScalar, _needsQuoting ...

  bool _isScalar(YamlNode node) {
    return node is YamlScalar;
  }

  bool _needsQuoting(String value) {
    if (value.isEmpty) return true;

    // Starts with special characters
    final firstChar = value[0];
    if (' \t-?:[]{}#&*!|>\'"%@`'.contains(firstChar)) {
      return true;
    }

    // Contains newlines or special characters
    if (value.contains('\n') || value.contains('\r') || value.contains('\t')) {
      return true;
    }

    // Could be interpreted as boolean, null, or number
    final lower = value.toLowerCase();
    if (lower == 'true' ||
        lower == 'false' ||
        lower == 'null' ||
        lower == 'yes' ||
        lower == 'no' ||
        lower == 'on' ||
        lower == 'off' ||
        lower == '~') {
      return true;
    }

    // Numeric-looking strings
    if (_looksNumeric(value)) {
      return true;
    }

    // Contains colon followed by space (could be confused with key: value)
    if (value.contains(': ') || value.endsWith(':')) {
      return true;
    }

    return false;
  }

  bool _looksNumeric(String value) {
    if (value.isEmpty) return false;
    final numPattern = RegExp(r'^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$');
    return numPattern.hasMatch(value);
  }

  void _write(String text) {
    _buffer.write(text);
  }

  void _writeLine(String text) {
    _buffer.writeln(text);
  }

  void _newLine() {
    _buffer.writeln();
  }

  void _writeIndent() {
    _buffer.write(' ' * (_indentLevel * options.tabWidth));
  }

  String _ensureTrailingNewline(String text) {
    final trimmed = text.trimRight();
    return trimmed.isEmpty ? '' : '$trimmed\n';
  }
}
