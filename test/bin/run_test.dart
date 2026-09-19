import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dapper/bin.dart';
import 'package:test/test.dart';

void main() {
  group('run', () {
    late int originalExitCode;

    setUp(() {
      originalExitCode = exitCode;
      exitCode = 0;
    });

    tearDown(() {
      exitCode = originalExitCode;
    });

    test('sets exitCode to 0 on success', () {
      // Suppress stdout to keep test output clean
      IOOverrides.runZoned(() => run(['--help']), stdout: () => _NullStdout());
      expect(exitCode, 0);
    });

    test('sets exitCode to 65 on error', () {
      // Suppress stdout/stderr to keep test output clean
      runZonedGuarded(() {
        IOOverrides.runZoned(
          () => run(['nonexistent_file']),
          stdout: () => _NullStdout(),
          stderr: () => _NullStdout(),
        );
      }, (error, stack) {});
      expect(exitCode, 65);
    });

    test('sets exitCode to 70 on unhandled exception', () {
      const mockCli = _MockDapperCli();
      final err = StringBuffer();

      // Suppress stdout/stderr to keep test output clean
      runZonedGuarded(() {
        IOOverrides.runZoned(
          () => run(['throwing'], cli: mockCli),
          stdout: () => _NullStdout(),
          stderr: () => _NullStdout(buffer: err),
        );
      }, (error, stack) {});

      expect(exitCode, 70);
      expect(err.toString(), 'Unexpected error: Exception: Simulated crash\n');
    });

    for (final flag in ['-v', '--verbose']) {
      test('prints terse stack trace on unhandled exception with $flag', () {
        const mockCli = _MockDapperCli();
        final err = StringBuffer();

        runZonedGuarded(() {
          IOOverrides.runZoned(
            () => run(['throwing', flag], cli: mockCli),
            stdout: () => _NullStdout(),
            stderr: () => _NullStdout(buffer: err),
          );
        }, (error, stack) {});

        expect(exitCode, 70);
        expect(err.toString(), startsWith('Unexpected error: '));
        expect(err.toString(), contains('run_test.dart'));
      });
    }

    /// Runs the CLI with a stdout whose `done` future fails with [error] and
    /// returns the errors that escaped `run`.
    Future<List<Object>> runWithFailingStdout(Object error) async {
      final errors = <Object>[];
      runZonedGuarded(() {
        // The failing future must be created in this zone; errors do not
        // cross error-zone boundaries.
        final done = Future<void>.error(error);
        IOOverrides.runZoned(
          () => run(['--help']),
          stdout: () => _NullStdout(done: done),
          stderr: () => _NullStdout(),
        );
      }, (error, stack) => errors.add(error));
      await pumpEventQueue();
      return errors;
    }

    test('ignores broken pipe on stdout', () async {
      final errors = await runWithFailingStdout(
        const FileSystemException(
          'writeFrom failed',
          '',
          OSError('Broken pipe', 32),
        ),
      );

      expect(errors, isEmpty);
      expect(exitCode, 0);
    });

    test('ignores broken pipe on socket stdout', () async {
      final errors = await runWithFailingStdout(
        const SocketException('Write failed', osError: OSError('', 32)),
      );

      expect(errors, isEmpty);
    });

    test('rethrows other stdout errors', () async {
      final errors = await runWithFailingStdout(StateError('boom'));

      expect(errors, [isA<StateError>()]);
    });
  });
}

class _MockDapperCli implements DapperCli {
  const _MockDapperCli();

  @override
  ExitCode run(List<String> arguments) {
    if (arguments.contains('throwing')) {
      throw Exception('Simulated crash');
    }
    return ExitCode.success;
  }

  @override
  ConfigLoader get configLoader => const ConfigLoader();

  @override
  FileSystem get fileSystem => const FileSystem();
}

class _NullStdout implements Stdout {
  _NullStdout({Future<void>? done, StringBuffer? buffer})
    : _done = done ?? Future.value(),
      _buffer = buffer ?? StringBuffer();

  final Future<void> _done;
  final StringBuffer _buffer;

  @override
  void write(Object? object) => _buffer.write(object);
  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);
  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {}
  @override
  void add(List<int> data) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<dynamic> addStream(Stream<List<int>> stream) => Future.value();
  @override
  Future<dynamic> flush() => Future.value();
  @override
  Future<dynamic> close() => Future.value();
  @override
  Future<dynamic> get done => _done;
  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding encoding) {}
  @override
  bool get hasTerminal => false;
  @override
  IOSink get nonBlocking => this;
  @override
  bool get supportsAnsiEscapes => false;
  @override
  int get terminalColumns => 80;
  @override
  int get terminalLines => 24;
  @override
  String get lineTerminator => '\n';
  @override
  set lineTerminator(String terminator) {}
}
