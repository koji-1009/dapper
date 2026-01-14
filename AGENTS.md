# AI Agent Design Guide

## Project Overview

**Dapper** is a Markdown and YAML formatter for Dart, inspired by **Prettier**.

Key design principles:

* Follow Prettier's formatting conventions where applicable
* Maintain 100% test coverage for `lib/`
* Support both CLI and library usage
* Cross-platform: works in Dart VM and JavaScript (browser)

## Architecture

```
dapper/
├── bin/dapper.dart     # CLI (dart:io dependent)
├── lib/                # Core library (platform-independent)
│   ├── dapper.dart     # Public API exports
│   └── src/
│       ├── markdown/   # Markdown formatter
│       │   ├── ast_printer.dart      # AST → Markdown string
│       │   ├── markdown_formatter.dart # Entry point
│       │   ├── normalizer.dart       # Prettier-style normalization
│       │   ├── definition_list.dart  # Definition list support
│       │   └── front_matter.dart     # YAML front matter extraction
│       ├── yaml/       # YAML formatter
│       │   └── yaml_formatter.dart   # Full YAML formatting
│       ├── utils/      # Shared utilities
│       │   └── text_utils.dart       # Text wrapping, normalization
│       └── options.dart              # FormatOptions class
├── test/               # Tests (mirrors lib/ structure)
└── docs/               # Web demo (compiles lib/ to JavaScript)
```

## Design Constraints

### lib/ Must Be Platform-Independent

Code under `lib/` **must not use dart:io**.

Reasons:

* The web demo in `docs/` compiles `lib/` to JavaScript
* dart:io is not available in browser environments
* Future cross-platform distribution (npm, etc.) is considered

### bin/dapper.dart Responsibilities

The following are intentionally placed in `bin/dapper.dart`:

| Class/Logic                     | Reason                            |
| ------------------------------- | --------------------------------- |
| `IgnorePattern` / `IgnoreRules` | Filesystem traversal              |
| `ConfigLoader`                  | File reading (dart:io)            |
| `DapperCli`                     | stdin/stdout operations (dart:io) |

Moving these to `lib/` is **not recommended**.

## Intentionally Unsupported Features

| Feature           | Reason                                        |
| ----------------- | --------------------------------------------- |
| HTML embedding    | Difficult to preserve exactly through parsing |
| Custom extensions | Keep implementation simple                    |

When users request these features, explain the design decision.

## Development Guidelines

### Adding New Features

1. Write tests first (TDD encouraged)
2. Ensure 100% coverage for new code
3. Create corresponding test file in `test/` (mirror `lib/` structure)
4. Follow Prettier's conventions when applicable

### Refactoring Rules

* Code splitting within `lib/src/` is allowed
* When moving code from `bin/` to `lib/`, verify no dart:io dependencies
* Use shared utilities from `text_utils.dart` to avoid duplication

### Common Commands

```bash
# Run all tests
dart test

# Run tests with coverage
dart test --coverage=coverage

# Static analysis
dart analyze

# Format check (CI)
dart run dapper -o none --set-exit-if-changed .

# Build web demo
dart compile js -O2 -o docs/dapper.js web/main.dart
```

## Coding Conventions

* Use `package:lints/recommended.yaml` lint rules
* Doc comments for all public APIs
* Avoid development notes in comments (e.g., "TODO", "FIXME")
* Keep functions focused and single-purpose
