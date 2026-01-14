import 'dart:io' as io;

/// Entry returned by [FileSystem.listDirectory].
class FileEntry {
  /// The full path of the entry.
  final String path;

  /// Whether this entry is a directory.
  final bool isDirectory;

  /// Creates a file entry.
  const FileEntry(this.path, {required this.isDirectory});
}

/// File system operations.
///
/// This class can be extended or replaced in tests using Dart's
/// implicit interface feature.
class FileSystem {
  /// Creates a file system instance.
  const FileSystem();

  /// Gets the type of the entity at the given path.
  io.FileSystemEntityType getType(String path) {
    return io.FileSystemEntity.typeSync(path);
  }

  /// Lists the entries in a directory.
  ///
  /// Throws if the directory cannot be read.
  List<FileEntry> listDirectory(String path) {
    final dir = io.Directory(path);
    return dir.listSync(recursive: false).map((entity) {
      return FileEntry(entity.path, isDirectory: entity is io.Directory);
    }).toList();
  }

  /// Reads the contents of a file.
  ///
  /// Throws if the file cannot be read.
  String readFile(String path) {
    return io.File(path).readAsStringSync();
  }

  /// Writes content to a file.
  void writeFile(String path, String content) {
    io.File(path).writeAsStringSync(content);
  }

  /// Gets the current working directory path.
  String get currentDirectory => io.Directory.current.path;
}
