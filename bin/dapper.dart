// Dapper CLI - Format Markdown and YAML files.
//
// Usage: dapper [options] <files or directories...>

import 'dart:io';

import 'package:dapper/bin.dart';

void main(List<String> arguments) {
  final result = const DapperCli().run(arguments);
  exit(result.code);
}
