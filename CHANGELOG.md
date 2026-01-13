## Next

### Changed

- Change default Markdown unordered list style from `-` (dash) to `*` (asterisk) to match Prettier's default behavior.

## 1.2.0

### Added

* Add `.dapperignore` and `.gitignore` support for excluding files and directories
  * Glob pattern matching (e.g., `*.generated.md`)
  * Negation patterns to override defaults (e.g., `!build`)
  * Nested ignore file support (child directories inherit parent rules)

## 1.1.1

### Fixed

* Fix extra blank lines being inserted between nested list items

## 1.1.0

### Fixed

* Add missing `executables` section to enable `dart pub global activate dapper` to work correctly
* Add `.pubignore` to reduce package size

## 1.0.4

### Changed

* Remove unused code

## 1.0.3

### Added

* Add interactive demo page with GitHub Pages support

## 1.0.2

### Fixed

* Fix bug where nested list items were rendered on the same line instead of new lines

## 1.0.1

### Fixed

* Normalize extra whitespace in list items (`*   Item` → `* Item`)
* Normalize extra whitespace in headings (`#    Title` → `# Title`)
* Normalize extra whitespace in blockquotes (`>    Text` → `> Text`)

### Changed

* Improved integration tests for messy input handling
* Updated example to demonstrate whitespace normalization

## 1.0.0

Initial release of Dapper * A simple Markdown and YAML formatter for Dart.

### Features

#### Markdown Formatting

* Emphasis normalization (`*text*` → `_text_`)
* List formatting with proper alignment (ordered and unordered)
* Configurable list bullet style (`-`, `*`, `+`)
* Code block preservation
* Table formatting with column alignment
* Prose wrapping (`always`, `never`, `preserve`)
* Definition list support
* Front matter preservation
* Setext to ATX heading conversion
* Deep nesting support

#### YAML Formatting

* Consistent, configurable indentation (default 2 spaces)
* Map and list formatting
* Nested structure support
* Automatic string quoting for special values
* Comment preservation (inline and block)

#### CLI

* Format files in place (`-o write`)
* Preview output (`-o show`)
* JSON output (`-o json`)
* CI check mode (`-o none --set-exit-if-changed`)
* Recursive directory processing
* Configurable print width and prose wrap

#### Configuration

* `dapper.yaml` configuration file support
* `analysis_options.yaml` integration
* CLI arguments override file configuration
