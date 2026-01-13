import 'package:dapper/dapper.dart';

void main() {
  print('==================================================');
  print('                  Dapper Example                  ');
  print('==================================================');

  // 1. Markdown Example
  // Demonstrates:
  // - List marker normalization (-, + -> *)
  // - Emphasis normalization (* -> _)
  // - Table alignment
  // - Checkbox formatting
  // - Heading & Blockquote whitespace normalization
  const markdown = '''
# Markdown Features

*   Misaligned list item
  * Nested item
*    Emphasis: *bold* and **italic**

| Column 1 | Column 2 |
| --- | :---: |
| Value 1 |   Value 2 |
| Long Value | Short |

- [ ] Unchecked
- [x] Checked

#    Whitespace in Heading

>    Whitespace in Blockquote
''';

  print('\n[Markdown Formatting]');
  print('\n[Before]');
  print(markdown);

  final formattedMarkdown = formatMarkdown(markdown);
  print('[After]');
  print(formattedMarkdown);

  // 2. YAML Example
  // Demonstrates:
  // - Indentation correction
  // - String quoting
  // - List formatting
  // - Comment preservation
  const yaml = '''
name:   my_package
version: 1.0.0


dependencies:
    # A dependency with a comment
    flutter:
      sdk: flutter
    dapper:   ^1.0.0  # inline comment


dev_dependencies:
  lints: '>=2.0.0 <3.0.0'
''';

  print('\n--------------------------------------------------');
  print('\n[YAML Formatting]');
  print('\n[Before]');
  print(yaml);

  final formattedYaml = formatYaml(
    yaml,
    options: const FormatOptions(tabWidth: 2),
  );
  print('[After]');
  print(formattedYaml);
}
