import 'dart:io';

import 'package:glob/glob.dart';

/// A single gitignore-style pattern with metadata.
///
/// Handles:
/// - Directory patterns (trailing `/`)
/// - Path-based patterns (containing `/`)
/// - Simple name patterns
class IgnorePattern {
  /// The glob pattern for matching.
  final Glob _glob;

  /// Whether this pattern contains a path separator (requires path matching).
  final bool hasPathSeparator;

  /// Whether this pattern is for directories only (originally ended with `/`).
  final bool isDirectoryOnly;

  IgnorePattern._(this._glob, this.hasPathSeparator, this.isDirectoryOnly);

  /// Parses a gitignore-style pattern.
  ///
  /// Returns `null` if the pattern is empty after normalization.
  static IgnorePattern? parse(String pattern) {
    var normalized = pattern;

    // Check if this is a directory-only pattern
    final isDirectoryOnly = normalized.endsWith('/');
    if (isDirectoryOnly) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    // Remove leading slash (anchors to root)
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    if (normalized.isEmpty) {
      return null;
    }

    // Check if pattern has path separator (requires path-based matching)
    final hasPathSeparator = normalized.contains('/');

    return IgnorePattern._(Glob(normalized), hasPathSeparator, isDirectoryOnly);
  }

  /// Checks if this pattern matches the given path.
  ///
  /// [relativePath] is the path relative to the gitignore location.
  /// [isDirectory] indicates if the path is a directory.
  bool matches(String relativePath, {required bool isDirectory}) {
    // Directory-only patterns should not match files
    if (isDirectoryOnly && !isDirectory) {
      return false;
    }

    if (hasPathSeparator) {
      // Pattern has path separator - match against full relative path
      return _glob.matches(relativePath);
    } else {
      // Pattern has no path separator - match against basename only
      return _glob.matches(basename(relativePath));
    }
  }
}

/// Rules for ignoring files and directories.
///
/// Supports glob patterns and negation patterns (prefixed with `!`).
class IgnoreRules {
  final List<IgnorePattern> _patterns;
  final Set<String> _negations;

  IgnoreRules._(this._patterns, this._negations);

  /// Creates empty rules.
  factory IgnoreRules.empty() => IgnoreRules._([], {});

  /// Parses ignore rules from file content.
  factory IgnoreRules.parse(String content) {
    final patterns = <IgnorePattern>[];
    final negations = <String>{};

    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      if (trimmed.startsWith('!')) {
        negations.add(trimmed.substring(1));
      } else {
        final pattern = IgnorePattern.parse(trimmed);
        if (pattern != null) {
          patterns.add(pattern);
        }
      }
    }

    return IgnoreRules._(patterns, negations);
  }

  /// Loads rules from a file, returns `null` if file doesn't exist.
  static IgnoreRules? loadFromFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }
    return IgnoreRules.parse(file.readAsStringSync());
  }

  /// Loads combined rules from `.gitignore` and `.dapperignore` in a directory.
  static IgnoreRules loadFromDirectory(String directoryPath) {
    var rules = IgnoreRules.empty();

    // Load .gitignore first (lower priority)
    final gitignore = loadFromFile('$directoryPath/.gitignore');
    if (gitignore != null) {
      rules = rules.merge(gitignore);
    }

    // Load .dapperignore second (higher priority)
    final dapperignore = loadFromFile('$directoryPath/.dapperignore');
    if (dapperignore != null) {
      rules = rules.merge(dapperignore);
    }

    return rules;
  }

  /// Whether this rules set is empty.
  bool get isEmpty => _patterns.isEmpty && _negations.isEmpty;

  /// Checks if an entry should be ignored.
  ///
  /// [name] is the basename of the entry.
  /// [relativePath] is the path relative to the root for path-based matching.
  /// [defaultIgnored] is a set of names that are always ignored.
  /// [isDirectory] indicates if the entry is a directory.
  bool shouldIgnore(
    String name,
    Set<String> defaultIgnored, {
    String? relativePath,
    bool isDirectory = false,
  }) {
    // Negation patterns can override defaults
    if (_negations.contains(name)) {
      return false;
    }

    // Check default ignored list
    if (defaultIgnored.contains(name)) {
      return true;
    }

    // Use relativePath for path-based patterns, otherwise use name
    final pathToMatch = relativePath ?? name;

    // Check glob patterns
    for (final pattern in _patterns) {
      if (pattern.matches(pathToMatch, isDirectory: isDirectory)) {
        return true;
      }
    }

    return false;
  }

  /// Merges this rules with another, creating combined rules.
  IgnoreRules merge(IgnoreRules other) {
    return IgnoreRules._(
      [..._patterns, ...other._patterns],
      {..._negations, ...other._negations},
    );
  }
}

/// Extracts the basename from a file path.
String basename(String path) {
  return Uri.file(path).pathSegments.lastWhere((s) => s.isNotEmpty);
}
