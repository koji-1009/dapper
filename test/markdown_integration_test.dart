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

      final formatter = MarkdownFormatter();
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

      final formatter = MarkdownFormatter();
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

        final formatter = MarkdownFormatter();
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

      final formatter = MarkdownFormatter();
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

      final formatter = MarkdownFormatter();
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

      final formatter = MarkdownFormatter();
      expect(formatter.format(input), expected);
    });
  });
}
