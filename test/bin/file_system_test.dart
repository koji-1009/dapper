import 'dart:io';

import 'package:dapper/bin.dart';
import 'package:test/test.dart';

void main() {
  group('FileSystem', () {
    late Directory tempDir;
    const fs = FileSystem();

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_system_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('getType returns notFound for non-existent path', () {
      expect(
        fs.getType('${tempDir.path}/nonexistent'),
        FileSystemEntityType.notFound,
      );
    });

    test('getType returns file for file', () {
      File('${tempDir.path}/test.txt').writeAsStringSync('hello');
      expect(fs.getType('${tempDir.path}/test.txt'), FileSystemEntityType.file);
    });

    test('getType returns directory for directory', () {
      Directory('${tempDir.path}/subdir').createSync();
      expect(
        fs.getType('${tempDir.path}/subdir'),
        FileSystemEntityType.directory,
      );
    });

    test('listDirectory returns entries', () {
      File('${tempDir.path}/file.txt').writeAsStringSync('content');
      Directory('${tempDir.path}/subdir').createSync();

      final entries = fs.listDirectory(tempDir.path);
      expect(entries.length, 2);

      final fileEntry = entries.firstWhere((e) => e.path.endsWith('file.txt'));
      expect(fileEntry.isDirectory, isFalse);

      final dirEntry = entries.firstWhere((e) => e.path.endsWith('subdir'));
      expect(dirEntry.isDirectory, isTrue);
    });

    test('readFile reads content', () {
      File('${tempDir.path}/test.txt').writeAsStringSync('hello world');
      expect(fs.readFile('${tempDir.path}/test.txt'), 'hello world');
    });

    test('writeFile writes content', () {
      fs.writeFile('${tempDir.path}/output.txt', 'written content');
      expect(
        File('${tempDir.path}/output.txt').readAsStringSync(),
        'written content',
      );
    });

    test('currentDirectory returns current directory', () {
      expect(fs.currentDirectory, Directory.current.path);
    });
  });

  group('FileEntry', () {
    test('stores path and isDirectory', () {
      const entry = FileEntry('/path/to/file', isDirectory: false);
      expect(entry.path, '/path/to/file');
      expect(entry.isDirectory, isFalse);

      const dirEntry = FileEntry('/path/to/dir', isDirectory: true);
      expect(dirEntry.isDirectory, isTrue);
    });
  });
}
