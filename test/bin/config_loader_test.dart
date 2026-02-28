import 'dart:io';

import 'package:dapper/bin.dart';
import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigLoader', () {
    late Directory tempDir;
    const loader = ConfigLoader();

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dapper_config_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('returns null when no config exists', () {
      expect(loader.loadFromDirectory(tempDir.path), isNull);
    });

    test('loads dapper.yaml', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
print_width: 100
tab_width: 4
prose_wrap: always
ul_style: dash
''');
      final options = loader.loadFromDirectory(tempDir.path);

      expect(options, isNotNull);
      expect(options!.printWidth, 100);
      expect(options.tabWidth, 4);
    });

    test('loads analysis_options.yaml dapper block', () {
      File('${tempDir.path}/analysis_options.yaml').writeAsStringSync('''
analyzer:
  errors:
    todo: ignore

dapper:
  print_width: 120
''');
      final options = loader.loadFromDirectory(tempDir.path);

      expect(options, isNotNull);
      expect(options!.printWidth, 120);
    });

    test('prefers dapper.yaml over analysis_options.yaml', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('print_width: 80');
      File('${tempDir.path}/analysis_options.yaml').writeAsStringSync('''
dapper:
  print_width: 120
''');
      final options = loader.loadFromDirectory(tempDir.path);

      expect(options!.printWidth, 80);
    });

    test('parses prose_wrap never and preserve', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
prose_wrap: never
''');
      var options = loader.loadFromDirectory(tempDir.path);
      expect(options!.proseWrap, ProseWrap.never);

      File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
prose_wrap: preserve
''');
      options = loader.loadFromDirectory(tempDir.path);
      expect(options!.proseWrap, ProseWrap.preserve);
    });

    test('parses ul_style asterisk and plus', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
ul_style: asterisk
''');
      var options = loader.loadFromDirectory(tempDir.path);
      expect(options!.ulStyle, UnorderedListStyle.asterisk);

      File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
ul_style: plus
''');
      options = loader.loadFromDirectory(tempDir.path);
      expect(options!.ulStyle, UnorderedListStyle.plus);
    });

    test('returns null for non-existent directory', () {
      expect(loader.loadFromDirectory('${tempDir.path}/non_existent'), isNull);
    });

    test('parses camelCase option names', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
printWidth: 100
tabWidth: 4
proseWrap: always
ulStyle: dash
''');
      final options = loader.loadFromDirectory(tempDir.path);
      expect(options, isNotNull);
      expect(options!.printWidth, 100);
      expect(options.tabWidth, 4);
      expect(options.proseWrap, ProseWrap.always);
      expect(options.ulStyle, UnorderedListStyle.dash);
    });

    test('parses ul_style shorthand values', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('ul_style: "-"');
      var options = loader.loadFromDirectory(tempDir.path);
      expect(options!.ulStyle, UnorderedListStyle.dash);

      File('${tempDir.path}/dapper.yaml').writeAsStringSync('ul_style: "*"');
      options = loader.loadFromDirectory(tempDir.path);
      expect(options!.ulStyle, UnorderedListStyle.asterisk);

      File('${tempDir.path}/dapper.yaml').writeAsStringSync('ul_style: "+"');
      options = loader.loadFromDirectory(tempDir.path);
      expect(options!.ulStyle, UnorderedListStyle.plus);
    });

    test('returns null for invalid config file', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('- item1\n- item2');
      expect(loader.loadFromDirectory(tempDir.path), isNull);
    });

    test('returns null when analysis_options.yaml has no dapper block', () {
      File('${tempDir.path}/analysis_options.yaml').writeAsStringSync('''
analyzer:
  errors:
    todo: ignore
''');
      expect(loader.loadFromDirectory(tempDir.path), isNull);
    });

    test('parses integer values from strings', () {
      File('${tempDir.path}/dapper.yaml').writeAsStringSync('''
print_width: "100"
tab_width: "4"
''');
      final options = loader.loadFromDirectory(tempDir.path);
      expect(options, isNotNull);
      expect(options!.printWidth, 100);
      expect(options.tabWidth, 4);
    });
  });
}
