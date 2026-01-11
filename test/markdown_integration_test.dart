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

- YAML formatting
- Markdown formatting

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
  });
}
