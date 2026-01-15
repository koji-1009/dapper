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
├── bin/dapper.dart     # CLI entry point (imports lib/bin.dart)
├── lib/
│   ├── dapper.dart     # Public API (platform-independent, web-safe)
│   ├── bin.dart        # CLI utilities (dart:io dependent, NOT web-safe)
│   ├── src/            # Core formatter logic (platform-independent)
│   │   ├── markdown/
│   │   ├── yaml/
│   │   ├── utils/
│   │   └── options.dart
│   └── bin/            # CLI implementation (dart:io dependent)
│       ├── config_loader.dart
│       ├── dapper_cli.dart
│       ├── exit_code.dart
│       ├── ignore_rules.dart
│       ├── output_mode.dart
│       └── process_result.dart
├── test/               # Tests (mirrors lib/ structure)
│   ├── src/            # Tests for lib/src/
│   └── bin/            # Tests for lib/bin/
└── docs/               # Web demo (compiles lib/dapper.dart to JavaScript)
```

## Design Constraints

### lib/dapper.dart Must Be Platform-Independent

`package:dapper/dapper.dart` **must not use dart:io**.

Reasons:

* The web demo in `docs/` compiles this to JavaScript
* dart:io is not available in browser environments
* Future cross-platform distribution (npm, etc.) is considered

### lib/bin.dart Contains dart:io Dependent Code

`package:dapper/bin.dart` **depends on dart:io** and can only be used in Dart VM environments.

| Class/Logic                     | Location   | Reason                            |
| ------------------------------- | ---------- | --------------------------------- |
| `IgnorePattern` / `IgnoreRules` | `lib/bin/` | Filesystem traversal              |
| `ConfigLoader`                  | `lib/bin/` | File reading (dart:io)            |
| `DapperCli`                     | `lib/bin/` | stdin/stdout operations (dart:io) |

> **WARNING**: Do not import `package:dapper/bin.dart` in web environments.

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
* dart:io dependent code goes in `lib/bin/`
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
