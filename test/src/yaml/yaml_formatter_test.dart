import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('YamlFormatter', () {
    late YamlFormatter formatter;

    setUp(() {
      formatter = YamlFormatter();
    });

    test('formats empty string', () {
      expect(formatter.format(''), '');
    });

    test('formats whitespace-only string', () {
      expect(formatter.format('   \n  '), '');
    });

    test('formats simple key-value pairs', () {
      final input = '''name:   myapp
version: 1.0.0''';
      final result = formatter.format(input);
      expect(result, contains('name: myapp'));
      expect(result, contains('version: 1.0.0'));
    });

    test('formats nested maps', () {
      final input = '''dependencies:
  flutter:
    sdk: flutter''';
      final result = formatter.format(input);
      expect(result, contains('dependencies:'));
      expect(result, contains('flutter:'));
      expect(result, contains('sdk: flutter'));
    });

    test('formats lists', () {
      final input = '''items:
  - first
  - second
  - third''';
      final result = formatter.format(input);
      expect(result, contains('items:'));
      expect(result, contains('- first'));
      expect(result, contains('- second'));
      expect(result, contains('- third'));
    });

    test('formats list of maps', () {
      final input = '''users:
  - name: Alice
    age: 30
  - name: Bob
    age: 25''';
      final result = formatter.format(input);
      expect(result, contains('name: Alice'));
      expect(result, contains('age: 30'));
      expect(result, contains('name: Bob'));
    });

    test('handles empty maps as values', () {
      final input = 'config: {}';
      final result = formatter.format(input);
      expect(result.trim(), 'config: {}');
    });

    test('handles empty lists as values', () {
      final input = 'items: []';
      final result = formatter.format(input);
      expect(result.trim(), 'items: []');
    });

    test('handles null values', () {
      final input = '''name: null
value: ~''';
      final result = formatter.format(input);
      expect(result, contains('name: null'));
      expect(result, contains('value: null'));
    });

    test('handles boolean values', () {
      final input = '''enabled: true
disabled: false''';
      final result = formatter.format(input);
      expect(result, contains('enabled: true'));
      expect(result, contains('disabled: false'));
    });

    test('handles numeric values', () {
      final input = '''port: 8080
ratio: 1.5''';
      final result = formatter.format(input);
      expect(result, contains('port: 8080'));
      expect(result, contains('ratio: 1.5'));
    });

    test('quotes strings that need quoting', () {
      final result = formatter.format('value: "hello world"');
      expect(result, contains('hello world'));
    });

    test('returns original on parse error', () {
      final input = 'invalid: yaml: syntax';
      final result = formatter.format(input);
      expect(result, input);
    });

    // Additional tests for 100% coverage

    test('handles top-level null', () {
      final result = formatter.format('null');
      expect(result.trim(), 'null');
    });

    test('handles top-level list', () {
      final input = '''- item1
- item2''';
      final result = formatter.format(input);
      expect(result, contains('- item1'));
      expect(result, contains('- item2'));
    });

    test('handles empty map in list', () {
      final input = '''items:
  - {}''';
      final result = formatter.format(input);
      expect(result, contains('- {}'));
    });

    test('handles empty list in list', () {
      final input = '''items:
  - []''';
      final result = formatter.format(input);
      expect(result, contains('- []'));
    });

    test('handles nested list in list', () {
      final input = '''items:
  - - nested1
    - nested2''';
      final result = formatter.format(input);
      expect(result, contains('nested1'));
      expect(result, contains('nested2'));
    });

    test('handles map with nested non-scalar first value in list', () {
      final input = '''items:
  - config:
      nested: value''';
      final result = formatter.format(input);
      expect(result, contains('config:'));
      expect(result, contains('nested: value'));
    });

    test('handles map with null first value in list', () {
      final input = '''items:
  - first: null
    second: value''';
      final result = formatter.format(input);
      expect(result, contains('first: null'));
      expect(result, contains('second: value'));
    });

    test('handles map with nested non-scalar remaining value in list', () {
      final input = '''items:
  - name: test
    config:
      key: value''';
      final result = formatter.format(input);
      expect(result, contains('name: test'));
      expect(result, contains('config:'));
      expect(result, contains('key: value'));
    });

    test('handles map with null remaining value in list', () {
      final input = '''items:
  - name: test
    value: null''';
      final result = formatter.format(input);
      expect(result, contains('name: test'));
      expect(result, contains('value: null'));
    });

    test('escapes special characters in strings', () {
      final input = 'message: "line1\\nline2"';
      final result = formatter.format(input);
      expect(result, contains('message:'));
    });

    test('quotes strings starting with special characters', () {
      final input = 'key: "#comment"';
      final result = formatter.format(input);
      expect(result, contains('"'));
    });

    test('quotes strings that look like booleans', () {
      final input = 'value: "true"';
      final result = formatter.format(input);
      expect(result, contains('"true"'));
    });

    test('quotes strings with colons', () {
      final input = 'url: "http://example.com"';
      final result = formatter.format(input);
      expect(result, contains('http://example.com'));
    });

    test('handles non-standard types by calling toString', () {
      final result = formatter.format('date: 2024-01-01');
      expect(result, contains('2024-01-01'));
    });

    test('respects tabWidth option', () {
      final customFormatter = YamlFormatter(const FormatOptions(tabWidth: 4));
      final input = '''root:
  nested: value''';
      final result = customFormatter.format(input);
      expect(result, contains('    nested'));
    });

    test('handles deeply nested structures', () {
      final input = '''level1:
  level2:
    level3:
      level4: value''';
      final result = formatter.format(input);
      expect(result, contains('level1:'));
      expect(result, contains('level4: value'));
    });

    // Formatting specific tests (from yaml_formatting_test.dart)

    test('trims leading newlines', () {
      const input = '\n\nname: dapper';
      const expected = 'name: dapper\n';
      expect(formatYaml(input), expected);
    });

    test('preserves single blank line between top-level items', () {
      const input = '''
name: dapper

description: nice
''';
      const expected = '''
name: dapper

description: nice
''';
      expect(formatYaml(input), expected);
    });

    test('normalizes multiple blank lines to one', () {
      const input = '''
name: dapper


description: nice
''';
      const expected = '''
name: dapper

description: nice
''';
      expect(formatYaml(input), expected);
    });

    test('maintains tight spacing if no blank line exists', () {
      const input = '''
name: dapper
description: nice
''';
      const expected = '''
name: dapper
description: nice
''';
      expect(formatYaml(input), expected);
    });

    test('preserves blank line before top-level comment', () {
      const input = '''
version: 0.1.0

# Comment
environment:
''';
      const expected = '''
version: 0.1.0

# Comment
environment:
''';
      expect(formatYaml(input), expected);
    });

    test('removes blank line before comment if none existed', () {
      const input = '''
version: 0.1.0
# Comment
environment:
''';
      const expected = '''
version: 0.1.0
# Comment
environment:
''';
      expect(formatYaml(input), expected);
    });

    test('preserves blank line after comment', () {
      const input = '''
# Comment

environment:
''';
      const expected = '''
# Comment

environment:
''';
      expect(formatYaml(input), expected);
    });

    test('handles list with comments', () {
      const input = '''
dependencies:
  # comment
  yaml: ^3.0.0
''';
      const expected = '''
dependencies:
  # comment
  yaml: ^3.0.0
''';
      expect(formatYaml(input), expected);
    });

    test('handles inline comments', () {
      const input = 'key: value # inline';
      const expected = 'key: value # inline\n';
      expect(formatYaml(input), expected);
    });

    test('preserves original indentation for section comments', () {
      const input = '''
root:
  child: value
# Section
  child2: value
''';
      const expected = '''
root:
  child: value
# Section
  child2: value
''';
      expect(formatYaml(input), expected);
    });

    test('handles quoted scalars', () {
      expect(formatYaml("key: 'single'"), "key: 'single'\n");
      expect(formatYaml('key: "double"'), 'key: "double"\n');
      expect(formatYaml('key: :unsafe'), 'key: ":unsafe"\n');
    });

    test('handles nested lists', () {
      const input = '''
list:
  - - a
    - b
''';
      const expected = '''
list:
  - 
    - a
    - b
''';
      expect(formatYaml(input), expected);
    });

    test('converts inline block map to block format', () {
      const input = 'key: { a: 1 }';
      const expected = '''
key:
  a: 1
''';
      expect(formatYaml(input), expected);
    });

    test('handles inline map with leading comment in list', () {
      const input = 'list: [ { # c\n a: 1 } ]';
      expect(formatYaml(input), contains('a: 1'));
    });

    test('handles flow map converted to block', () {
      const input = 'key: { a: 1, b: 2 }';
      const expected = '''
key:
  a: 1
  b: 2
''';
      expect(formatYaml(input), expected);
    });
  });

  group('formatYaml convenience function', () {
    test('formats with default options', () {
      final result = formatYaml('name: test');
      expect(result.trim(), 'name: test');
    });

    test('accepts custom options', () {
      final result = formatYaml(
        'name: test',
        options: const FormatOptions(tabWidth: 4),
      );
      expect(result, contains('name: test'));
    });

    test('handles unknown tags in list', () {
      final formatter = YamlFormatter();
      final input = '- !!custom value';
      final result = formatter.format(input);
      expect(result, contains('value'));
    });
  });
}
