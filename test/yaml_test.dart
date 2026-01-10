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

    test('handles empty maps', () {
      final input = 'config: {}';
      final result = formatter.format(input);
      expect(result.trim(), 'config: {}');
    });

    test('handles empty lists', () {
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
  });
}
