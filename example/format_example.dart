/// Example usage of the Dapper Markdown formatter.
///
/// Run with: dart run example/format_example.dart
library;

import 'package:dapper/dapper.dart';

void main() {
  // Sample markdown content
  const markdown = '''
# Welcome to Dapper

This is a *simple* markdown formatter inspired by **Prettier**.

## Features

- Emphasis normalization: *converts* asterisk to underscore
- List formatting with proper alignment
- Code block preservation

## Code Example

```dart
void main() {
  print('Hello, World!');
}
```

## Table Example

| Name  | Age | City     |
|-------|-----|----------|
| Alice | 30  | New York |
| Bob   | 25  | London   |

---

> This is a blockquote.
> It can span multiple lines.

Check out [the docs](https://example.com) for more information.
''';

  print('=== Original ===');
  print(markdown);

  print('\n=== Formatted (default options) ===');
  final formatter = MarkdownFormatter();
  print(formatter.format(markdown));

  print('\n=== Formatted (proseWrap: always, printWidth: 60) ===');
  final wrappingFormatter = MarkdownFormatter(
    const FormatOptions(proseWrap: ProseWrap.always, printWidth: 60),
  );
  print(wrappingFormatter.format(markdown));
}
