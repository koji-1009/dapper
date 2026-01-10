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

    test('defaults static constant matches constructor defaults', () {
      expect(FormatOptions.defaults.printWidth, 80);
      expect(FormatOptions.defaults.tabWidth, 2);
      expect(FormatOptions.defaults.proseWrap, ProseWrap.preserve);
    });

    test('accepts custom values', () {
      const options = FormatOptions(
        printWidth: 120,
        tabWidth: 4,
        proseWrap: ProseWrap.always,
      );
      expect(options.printWidth, 120);
      expect(options.tabWidth, 4);
      expect(options.proseWrap, ProseWrap.always);
    });

    group('copyWith', () {
      test('modifies printWidth only', () {
        const original = FormatOptions();
        final modified = original.copyWith(printWidth: 120);
        expect(modified.printWidth, 120);
        expect(modified.tabWidth, original.tabWidth);
        expect(modified.proseWrap, original.proseWrap);
      });

      test('modifies tabWidth only', () {
        const original = FormatOptions();
        final modified = original.copyWith(tabWidth: 4);
        expect(modified.printWidth, original.printWidth);
        expect(modified.tabWidth, 4);
        expect(modified.proseWrap, original.proseWrap);
      });

      test('modifies proseWrap only', () {
        const original = FormatOptions();
        final modified = original.copyWith(proseWrap: ProseWrap.always);
        expect(modified.printWidth, original.printWidth);
        expect(modified.tabWidth, original.tabWidth);
        expect(modified.proseWrap, ProseWrap.always);
      });

      test('preserves all fields when no arguments', () {
        const original = FormatOptions(
          printWidth: 100,
          tabWidth: 4,
          proseWrap: ProseWrap.always,
        );
        final modified = original.copyWith();
        expect(modified.printWidth, 100);
        expect(modified.tabWidth, 4);
        expect(modified.proseWrap, ProseWrap.always);
      });
    });

    group('equality', () {
      test('equal options are equal', () {
        const a = FormatOptions(printWidth: 80, tabWidth: 2);
        const b = FormatOptions(printWidth: 80, tabWidth: 2);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different printWidth are not equal', () {
        const a = FormatOptions(printWidth: 80);
        const b = FormatOptions(printWidth: 100);
        expect(a, isNot(equals(b)));
      });

      test('different tabWidth are not equal', () {
        const a = FormatOptions(tabWidth: 2);
        const b = FormatOptions(tabWidth: 4);
        expect(a, isNot(equals(b)));
      });

      test('different proseWrap are not equal', () {
        const a = FormatOptions(proseWrap: ProseWrap.always);
        const b = FormatOptions(proseWrap: ProseWrap.never);
        expect(a, isNot(equals(b)));
      });

      test('identical returns true for same instance', () {
        const options = FormatOptions();
        expect(options, equals(options));
      });

      test('different types are not equal', () {
        const options = FormatOptions();
        expect(options, isNot(equals('not options')));
      });
    });

    test('toString returns readable representation', () {
      const options = FormatOptions(
        printWidth: 100,
        tabWidth: 4,
        proseWrap: ProseWrap.always,
      );
      final str = options.toString();
      expect(str, contains('FormatOptions'));
      expect(str, contains('printWidth: 100'));
      expect(str, contains('tabWidth: 4'));
      expect(str, contains('proseWrap: ProseWrap.always'));
    });
  });

  group('ProseWrap', () {
    test('has all expected values', () {
      expect(ProseWrap.values, contains(ProseWrap.always));
      expect(ProseWrap.values, contains(ProseWrap.never));
      expect(ProseWrap.values, contains(ProseWrap.preserve));
      expect(ProseWrap.values.length, 3);
    });
  });
}
