@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:dapper/src/version.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;
import 'package:test_process/test_process.dart';

final _entrypoint = p.absolute('bin', 'dapper.dart');

Future<TestProcess> _startDapper(List<String> args) {
  return TestProcess.start('dart', [
    'run',
    _entrypoint,
    ...args,
  ], workingDirectory: d.sandbox);
}

void main() {
  test('--help prints usage to stdout and exits 0', () async {
    final process = await _startDapper(['--help']);

    await expectLater(
      process.stdout,
      emitsThrough('Usage: dapper [options] <files or directories...>'),
    );
    await process.shouldExit(0);
  });

  test('--version prints the package version', () async {
    final process = await _startDapper(['--version']);

    await expectLater(process.stdout, emits('dapper $packageVersion'));
    await process.shouldExit(0);
  });

  test('invalid option prints usage to stderr and exits 64', () async {
    final process = await _startDapper(['--bogus']);

    await expectLater(
      process.stderr,
      emits('Error: Could not find an option named "--bogus".'),
    );
    await expectLater(
      process.stderr,
      emitsThrough('Usage: dapper [options] <files or directories...>'),
    );
    await expectLater(process.stdout, emitsDone);
    await process.shouldExit(64);
  });

  test('missing path exits 65', () async {
    final process = await _startDapper(['missing.md']);

    await expectLater(process.stderr, emits('Error: "missing.md" not found.'));
    await process.shouldExit(65);
  });

  test('--set-exit-if-changed exits 1 when a file changes', () async {
    await d.file('a.md', '*emphasis*\n').create();

    final process = await _startDapper([
      '-o',
      'none',
      '--set-exit-if-changed',
      'a.md',
    ]);

    await process.shouldExit(1);
    await d.file('a.md', '*emphasis*\n').validate();
  });

  test('write mode formats files in place', () async {
    await d.file('a.md', '*emphasis*\n').create();

    final process = await _startDapper(['a.md']);

    await expectLater(process.stdout, emits('Formatted a.md'));
    await process.shouldExit(0);
    await d.file('a.md', '_emphasis_\n').validate();
  });

  test('exits 0 when stdout is closed early', () async {
    await d.file('a.md', List.filled(20000, 'line\n\n').join()).create();

    final process = await Process.start('dart', [
      'run',
      _entrypoint,
      '-o',
      'show',
      'a.md',
    ], workingDirectory: d.sandbox);
    final stderrText = process.stderr
        .transform(const SystemEncoding().decoder)
        .join();

    await process.stdout.first;

    expect(await process.exitCode, 0);
    expect(await stderrText, isNot(contains('Broken pipe')));
  });
}
