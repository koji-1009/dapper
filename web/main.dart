import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dapper/dapper.dart';

@JS('formatMarkdown')
external set _formatMarkdown(JSFunction fn);

@JS('formatYaml')
external set _formatYaml(JSFunction fn);

void main() {
  _formatMarkdown = ((JSString s, [JSObject? o]) => formatMarkdown(
    s.toDart,
    options: FormatOptions(
      proseWrap: _enum(ProseWrap.values, o?['proseWrap'], ProseWrap.preserve),
      printWidth: (o?['printWidth'] as JSNumber?)?.toDartInt ?? 80,
      ulStyle: _enum(
        UnorderedListStyle.values,
        o?['ulStyle'],
        UnorderedListStyle.dash,
      ),
    ),
  ).toJS).toJS;

  _formatYaml = ((JSString s) => formatYaml(s.toDart).toJS).toJS;
}

T _enum<T extends Enum>(List<T> values, JSAny? v, T def) {
  final name = v != null && v.isA<JSString>() ? (v as JSString).toDart : null;
  return values.firstWhere((e) => e.name == name, orElse: () => def);
}
