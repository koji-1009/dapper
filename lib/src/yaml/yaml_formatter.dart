/// YAML formatter.
///
/// Formats YAML documents with consistent indentation and style.
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

    try {
      final doc = loadYaml(yaml);
      final printer = _YamlPrinter(options);
      return printer.print(doc);
    } catch (e) {
      // If parsing fails, return original content
      return yaml;
    }
  }
}

/// Convenience function to format YAML with default options.
String formatYaml(String yaml, {FormatOptions? options}) {
  final formatter = YamlFormatter(options);
  return formatter.format(yaml);
}

class _YamlPrinter {
  final FormatOptions options;
  final StringBuffer _buffer = StringBuffer();
  int _indentLevel = 0;

  _YamlPrinter(this.options);

  String print(dynamic value) {
    _buffer.clear();
    _printValue(value, inline: false);
    return _ensureTrailingNewline(_buffer.toString());
  }

  void _printValue(dynamic value, {required bool inline}) {
    if (value == null) {
      _write('null');
    } else if (value is YamlMap || value is Map) {
      _printMap(value as Map, inline: inline);
    } else if (value is YamlList || value is List) {
      _printList(value as List);
    } else if (value is String) {
      _printString(value);
    } else if (value is bool) {
      _write(value ? 'true' : 'false');
    } else {
      _write(value.toString());
    }
  }

  void _printMap(Map<dynamic, dynamic> map, {required bool inline}) {
    // Note: map.isEmpty check is handled by caller (_printValue)

    final entries = map.entries.toList();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final key = entry.key.toString();
      final value = entry.value;

      if (i > 0 || !inline) {
        _writeIndent();
      }

      _write('$key:');

      if (value == null) {
        _writeLine(' null');
      } else if (_isScalar(value)) {
        _write(' ');
        _printValue(value, inline: true);
        _newLine();
      } else if (value is Map && value.isEmpty) {
        _writeLine(' {}');
      } else if (value is List && value.isEmpty) {
        _writeLine(' []');
      } else {
        _newLine();
        _indentLevel++;
        _printValue(value, inline: false);
        _indentLevel--;
      }
    }
  }

  void _printList(List<dynamic> list) {
    // Note: list.isEmpty check is handled by caller (_printValue)

    for (final item in list) {
      _writeIndent();
      _write('- ');

      if (_isScalar(item)) {
        _printValue(item, inline: true);
        _newLine();
      } else if (item is Map) {
        if (item.isEmpty) {
          _writeLine('{}');
        } else {
          // For maps in lists, print first key on same line
          final entries = item.entries.toList();
          final firstEntry = entries.first;
          _write('${firstEntry.key}:');

          if (_isScalar(firstEntry.value)) {
            _write(' ');
            _printValue(firstEntry.value, inline: true);
            _newLine();
          } else {
            _newLine();
            _indentLevel++;
            _printValue(firstEntry.value, inline: false);
            _indentLevel--;
          }

          // Print remaining entries with proper indentation
          if (entries.length > 1) {
            _indentLevel++;
            for (var i = 1; i < entries.length; i++) {
              final entry = entries[i];
              _writeIndent();
              _write('${entry.key}:');

              if (_isScalar(entry.value)) {
                _write(' ');
                _printValue(entry.value, inline: true);
                _newLine();
              } else {
                _newLine();
                _indentLevel++;
                _printValue(entry.value, inline: false);
                _indentLevel--;
              }
            }
            _indentLevel--;
          }
        }
      } else if (item is List) {
        if (item.isEmpty) {
          _writeLine('[]');
        } else {
          _newLine();
          _indentLevel++;
          _printValue(item, inline: false);
          _indentLevel--;
        }
      }
    }
  }

  void _printString(String value) {
    // Check if string needs quoting
    if (_needsQuoting(value)) {
      // Use double quotes and escape special characters
      final escaped = value
          .replaceAll(r'\', r'\\')
          .replaceAll('"', r'\"')
          .replaceAll('\n', r'\n')
          .replaceAll('\r', r'\r')
          .replaceAll('\t', r'\t');
      _write('"$escaped"');
    } else {
      _write(value);
    }
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

  bool _isScalar(dynamic value) {
    return value == null || value is String || value is num || value is bool;
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
