## 1.0.0

Initial release of Dapper - A simple Markdown and YAML formatter for Dart.

### Features

#### Markdown Formatting

- Emphasis normalization (`*text*` → `_text_`)
- List formatting with proper alignment (ordered and unordered)
- Configurable list bullet style (`-`, `*`, `+`)
- Code block preservation
- Table formatting with column alignment
- Prose wrapping (`always`, `never`, `preserve`)
- Definition list support
- Front matter preservation
- Setext to ATX heading conversion
- Deep nesting support

#### YAML Formatting

- Consistent, configurable indentation (default 2 spaces)
- Map and list formatting
- Nested structure support
- Automatic string quoting for special values
- Comment preservation (inline and block)

#### CLI

- Format files in place (`-o write`)
- Preview output (`-o show`)
- JSON output (`-o json`)
- CI check mode (`-o none --set-exit-if-changed`)
- Recursive directory processing
- Configurable print width and prose wrap

#### Configuration

- `dapper.yaml` configuration file support
- `analysis_options.yaml` integration
- CLI arguments override file configuration
