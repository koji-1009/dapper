/// Tests for FormatOptions.
library;

import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('FormatOptions', () {
    test('has sensible defaults', () {
      const options = FormatOptions();
      expect(options.printWidth, 80);
      expect(options.tabWidth, 2);
      expect(options.proseWrap, ProseWrap.preserve);
    });

    test('copyWith creates modified copy', () {
      const original = FormatOptions();
      final modified = original.copyWith(printWidth: 120);
      expect(modified.printWidth, 120);
      expect(modified.tabWidth, original.tabWidth);
    });

    test('copyWith preserves all fields', () {
      const original = FormatOptions(
        printWidth: 100,
        tabWidth: 4,
        proseWrap: ProseWrap.always,
      );
      final modified = original.copyWith(printWidth: 80);
      expect(modified.printWidth, 80);
      expect(modified.tabWidth, 4);
      expect(modified.proseWrap, ProseWrap.always);
    });
  });
}
