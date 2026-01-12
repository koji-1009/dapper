import 'dart:js_interop';

import 'package:dapper/dapper.dart';

@JS('formatMarkdown')
external set _formatMarkdown(JSFunction fn);

@JS('formatYaml')
external set _formatYaml(JSFunction fn);

void main() {
  _formatMarkdown = ((JSString s, [MarkdownOptions? o]) => formatMarkdown(
    s.toDart,
    options: o != null
        ? FormatOptions(
            proseWrap: o.proseWrapDart,
            printWidth: o.printWidthDart,
            ulStyle: o.ulStyleDart,
          )
        : null,
  ).toJS).toJS;

  _formatYaml = ((JSString s) => formatYaml(s.toDart).toJS).toJS;
}

extension type const MarkdownOptions._(JSObject o) implements JSObject {
  external String? get proseWrap;
  external int? get printWidth;
  external String? get ulStyle;

  ProseWrap get proseWrapDart => switch (proseWrap) {
    'always' => ProseWrap.always,
    'never' => ProseWrap.never,
    'preserve' => ProseWrap.preserve,
    _ => ProseWrap.preserve,
  };
  int get printWidthDart => printWidth ?? 80;
  UnorderedListStyle get ulStyleDart => switch (ulStyle) {
    'dash' => UnorderedListStyle.dash,
    'asterisk' => UnorderedListStyle.asterisk,
    'plus' => UnorderedListStyle.plus,
    _ => UnorderedListStyle.dash,
  };
}
