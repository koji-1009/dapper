import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('YAML Integration Tests', () {
    test('formats a complex pubspec.yaml correctly', () {
      const input = '''
name: dapper
description: A shiny new package.
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  path: ^1.8.0
  yaml: ^3.1.0

dev_dependencies:
  lints: ^2.0.0
  test: ^1.21.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/fonts/
''';
      // Ideally, dapper preserves this structure exactly (or normalizes it consistently).
      // Assuming normalization preserves blank lines and indentation.
      const expected = '''
name: dapper
description: A shiny new package.
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  path: ^1.8.0
  yaml: ^3.1.0

dev_dependencies:
  lints: ^2.0.0
  test: ^1.21.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/fonts/
''';
      expect(formatYaml(input), expected);
    });

    test('formats a GitHub Actions workflow correctly', () {
      const input = '''
name: CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Dart
        uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze project source
        run: dart analyze

      - name: Run tests
        run: dart test
''';

      const expected = '''
name: CI

on:
  push:
    branches:
      - "main"
  pull_request:
    branches:
      - "main"

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Dart
        uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze project source
        run: dart analyze

      - name: Run tests
        run: dart test
''';
      expect(formatYaml(input), expected);
    });

    test('formats a messy YAML correctly', () {
      const input = '''
name:   my_package
version:    1.0.0


dependencies:
    # A dependency with a comment
    flutter:
      sdk: flutter
    dapper:   ^1.0.0  


dev_dependencies:
  lints: '>=2.0.0 <3.0.0'
''';

      const expected = '''
name: my_package
version: 1.0.0

dependencies:
  # A dependency with a comment
  flutter:
    sdk: flutter
  dapper: ^1.0.0

dev_dependencies:
  lints: '>=2.0.0 <3.0.0'
''';

      expect(formatYaml(input), expected);
    });
  });
}
