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
      run(['--help']);
      expect(exitCode, 0);
    });

    test('sets exitCode to 1 on error', () {
      // Suppress stderr to keep test output clean
      runZonedGuarded(() {
        IOOverrides.runZoned(
          () => run(['nonexistent_file']),
          stderr: () => _NullStdout(),
        );
      }, (error, stack) {});
      expect(exitCode, 1);
    });

    test('sets exitCode to 1 on unhandled exception', () {
      const mockCli = _MockDapperCli();

      // Suppress stderr
      runZonedGuarded(() {
        IOOverrides.runZoned(
          () => run(['throwing'], cli: mockCli),
          stderr: () => _NullStdout(),
        );
      }, (error, stack) {});

      expect(exitCode, 1);
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
  @override
  void write(Object? object) {}
  @override
  void writeln([Object? object = '']) {}
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
  Future<dynamic> get done => Future.value();
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
