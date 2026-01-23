import 'package:dapper/dapper.dart';
import 'package:test/test.dart';

void main() {
  group('Markdown Integration Tests', () {
    test('formats a full document correctly', () {
      const input = '''
---
title: Dapper Documentation
author: Koji
---

# Introduction

Dapper is a *fantastic* formatter.

## Features

- YAML formatting
- Markdown formatting

## `dapper` Usage

## Code Example

```dart
void main() {
  print('Hello');
}
```

## Definition List

Term
: Definition
''';

      const expected = '''
---
title: Dapper Documentation
author: Koji
---

# Introduction

Dapper is a _fantastic_ formatter.

## Features

* YAML formatting
* Markdown formatting

## `dapper` Usage

## Code Example

```dart
void main() {
  print('Hello');
}
```

## Definition List

Term
: Definition

''';

      const formatter = MarkdownFormatter();
      expect(formatter.format(input), expected);
    });

    test('formats a messy document correctly', () {
      const input = '''
#    Heading with spaces

*   Misaligned list item
  * Nested item
*    Emphasis: *bold*

| Column 1 | Column 2 |
| --- | :---: |
| Value 1 |   Value 2 |

>    Blockquote with spaces
''';

      const expected = '''
# Heading with spaces

* Misaligned list item
* Nested item
* Emphasis: _bold_

| Column 1 | Column 2 |
| -------- |:--------:|
| Value 1  | Value 2  |

> Blockquote with spaces
''';

      const formatter = MarkdownFormatter();
      expect(formatter.format(input), expected);
    });
    test(
      'does not add extra newline after list item containing code block',
      () {
        const input = '''
* A
  ```
  abc
  ```
* B
  ```
  abc
  ```
''';

        const expected = '''
* A
  ```
  abc
  ```
* B
  ```
  abc
  ```
''';

        const formatter = MarkdownFormatter();
        expect(formatter.format(input), expected);
      },
    );
    test('formats checkbox list item with code block correctly', () {
      const input = '''
- [ ] Task 1
  ```
  code inside
  ```
''';

      const expected = '''
* [ ] Task 1
  ```
  code inside
  ```
''';

      const formatter = MarkdownFormatter();
      expect(formatter.format(input), expected);
    });

    test('formats blockquote with list correctly', () {
      const input = '''
> * Item 1
> * Item 2
''';

      const expected = '''
> * Item 1
> * Item 2
''';

      const formatter = MarkdownFormatter();
      expect(formatter.format(input), expected);
    });

    test('formats nested blockquote correctly', () {
      const input = '''
> Level 1
>> Level 2
''';

      const expected = '''
> Level 1
>
> > Level 2
''';

      const formatter = MarkdownFormatter();
      expect(formatter.format(input), expected);
    });

    group('HTML comments', () {
      test('preserves blank line after HTML comment', () {
        const input = '''<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.
''';

        const formatter = MarkdownFormatter();
        final result = formatter.format(input);

        // Should preserve the blank line between --> and TODO
        expect(result, contains('-->\n\n'));
        expect(result, contains('TODO: Put a short description'));
      });

      test('preserves formatting idempotently', () {
        const input = '''<!--
Comment here
-->

Paragraph text.
''';

        const formatter = MarkdownFormatter();
        final once = formatter.format(input);
        final twice = formatter.format(once);

        expect(twice, once, reason: 'Formatting should be idempotent');
      });

      test('handles single line HTML comment with following content', () {
        const input = '''<!-- short comment -->

Next paragraph here.
''';

        const formatter = MarkdownFormatter();
        final result = formatter.format(input);

        expect(result, contains('<!-- short comment -->'));
        expect(result, contains('\n\n'));
        expect(result, contains('Next paragraph here'));
      });
    });
  });
}
