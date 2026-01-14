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
  });
}
