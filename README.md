# Dapper

A simple Markdown (and YAML) formatter for Dart, inspired by Prettier.

## Features

### Markdown Formatting
- **Emphasis normalization**: `*text*` → `_text_`
- **List formatting**: Ordered/unordered lists with proper alignment
- **Code block preservation**: Maintains code block content
- **Table formatting**: Aligns columns and normalizes separators
- **Prose wrapping**: Optional line wrapping at specified width
- **Definition lists**: Term/definition formatting
- **Front matter**: YAML front matter preserved unchanged
- **Setext headings**: Converted to ATX style (`#`)
- **Deep nesting**: Supports arbitrary nesting levels

### Format Options
- `printWidth`: Maximum line width (default: 80)
- `tabWidth`: Spaces per indentation level (default: 2)
- `proseWrap`: `always` | `never` | `preserve`

## Usage

```dart
import 'package:dapper/dapper.dart';

void main() {
  final formatter = MarkdownFormatter();
  
  final result = formatter.format('''
# Hello

*emphasis* and **strong**
''');
  
  print(result);
  // Output:
  // # Hello
  //
  // _emphasis_ and **strong**
}
```

### With Options

```dart
final formatter = MarkdownFormatter(
  const FormatOptions(
    proseWrap: ProseWrap.always,
    printWidth: 60,
  ),
);
```

## CLI Usage

```bash
# Format files in place
dart run dapper README.md

# Show formatted output without writing
dart run dapper -o show README.md

# Check if files need formatting (for CI)
dart run dapper -o none --set-exit-if-changed .

# Format all markdown files in a directory
dart run dapper docs/
```

### CLI Options

```
Usage: dapper [options] <files or directories...>

-h, --help                     Print this usage information.
-o, --output=<mode>            Set where to write formatted output.
          [write] (default)    Overwrite formatted files on disk.
          [show]               Print code to terminal.
          [none]               Discard output.
    --set-exit-if-changed      Return exit code 1 if there are any changes.
    --print-width=<int>        Maximum line width. (default: 80)
    --prose-wrap=<mode>        How to wrap prose. [always, never, preserve]
```

### CI Integration

```yaml
# GitHub Actions example
- name: Check formatting
  run: dart run dapper -o none --set-exit-if-changed .
```

## Dropped Features

The following features are intentionally not supported to keep the implementation simple:

| Feature | Reason |
|---------|--------|
| HTML embedding | Difficult to preserve exactly through parsing. |

## Development

```bash
# Run tests
dart test

# Run example
dart run example/format_example.dart

# Analyze
dart analyze
```

## License

MIT
