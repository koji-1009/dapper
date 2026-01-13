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
  });
}
