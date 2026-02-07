# Dapper

[![pub package](https://img.shields.io/pub/v/dapper.svg)](https://pub.dev/packages/dapper)
[![demo](https://img.shields.io/badge/demo-online-brightgreen)](https://koji-1009.github.io/dapper/)
[![analyze](https://github.com/koji-1009/dapper/actions/workflows/analyze.yml/badge.svg)](https://github.com/koji-1009/dapper/actions/workflows/analyze.yml)
[![codecov](https://codecov.io/gh/koji-1009/dapper/graph/badge.svg)](https://codecov.io/gh/koji-1009/dapper)

A simple Markdown and YAML formatter for Dart, inspired by Prettier.

## Features

### Markdown Formatting

* **Emphasis normalization**: `*text*` → `_text_`
* **List formatting**: Ordered/unordered lists with proper alignment
* **Code block preservation**: Maintains code block content
* **Table formatting**: Aligns columns and normalizes separators
* **Prose wrapping**: Optional line wrapping at specified width
* **Definition lists**: Term/definition formatting
* **Front matter**: YAML front matter preserved unchanged
* **Setext headings**: Converted to ATX style (`#`)
* **Deep nesting**: Supports arbitrary nesting levels

### YAML Formatting

* **Consistent indentation**: Normalizes to 2-space indent
* **Map formatting**: Key-value pairs with proper spacing
* **List formatting**: Block style with proper indentation
* **Nested structures**: Deep map/list nesting
* **String quoting**: Automatic quoting for special values
* **Comment preservation**: Inline and block comments preserved

## Usage

```dart
import 'package:dapper/dapper.dart';

void main() {
  final result = formatMarkdown('''
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
final result = formatMarkdown(
  content,
  options: const FormatOptions(
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

# Output as JSON
dart run dapper -o json README.md

# Check if files need formatting (for CI)
dart run dapper -o none --set-exit-if-changed .

# Format all markdown/yaml files in a directory
dart run dapper docs/
```

### CLI Options

```
Usage: dapper [options] <files or directories...>

-h, --help                     Print this usage information.
-o, --output=<mode>            Set where to write formatted output.
          [write] (default)    Overwrite formatted files on disk.
          [show]               Print code to terminal.
          [json]               Print code as JSON.
          [none]               Discard output.
    --set-exit-if-changed      Return exit code 1 if there are any changes.
    --print-width=<int>        Maximum line width. (default: 80)
    --prose-wrap=<mode>        How to wrap prose. [always, never, preserve]
```

## Configuration

Dapper can be configured via configuration files. Options are read in this order (later overrides earlier):

1. **Default values**
2. **`analysis_options.yaml`** (in `dapper:` block)
3. **`dapper.yaml`** (project root)
4. **CLI arguments** (highest priority)

### dapper.yaml

```yaml
print_width: 100
tab_width: 4
prose_wrap: always
ul_style: asterisk  # dash, asterisk, or plus
```

### analysis_options.yaml

```yaml
analyzer:
  # ...your analyzer settings

dapper:
  print_width: 100
  prose_wrap: preserve
```

### CI Integration

```yaml
# GitHub Actions example
- name: Check formatting
  run: dart run dapper -o none --set-exit-if-changed .
```

## Ignoring Files

Dapper respects `.gitignore` and `.dapperignore` files to exclude files and directories from formatting.

### Default Ignored Directories

These directories are always skipped (unless overridden with `!`):
`.git`, `.dart_tool`, `.idea`, `.vscode`, `.fvm`

### .dapperignore

Create a `.dapperignore` file in your project root:

```
# Dependencies
node_modules
Pods

# Generated files
*.generated.md
```

**Features:**

* Glob patterns (`*.generated.md`, `docs/**/*.md`)
* Negation patterns (`!build` to include a default-ignored directory)
* Nested support (child directories inherit parent rules)
* `.gitignore` integration (patterns from `.gitignore` are also applied)

## Format Options

| Option        | Type   | Default    | Markdown | YAML |
| ------------- | ------ | ---------- | -------- | ---- |
| `print_width` | int    | 80         | ✓        | ✗    |
| `tab_width`   | int    | 2          | ✓        | ✓    |
| `prose_wrap`  | string | `preserve` | ✓        | ✗    |
| `ul_style`    | string | `dash`     | ✓        | ✗    |

## Dropped Features

The following features are intentionally not supported to keep the implementation simple:

| Feature        | Reason                                         |
| -------------- | ---------------------------------------------- |
| HTML embedding | Difficult to preserve exactly through parsing. |

## Development

```bash
# Run tests
dart test

# Analyze
dart analyze

# Format the project itself
dart run bin/dapper.dart .
```

## License

MIT License - see [LICENSE](LICENSE) for details.
